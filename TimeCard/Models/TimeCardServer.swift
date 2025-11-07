//
//  TimeCardServer.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/28.
//

import Foundation
import NIO
import NIOHTTP1
import NIOFoundationCompat
import SwiftData

class TimeCardServer {
    private let host: String = "0.0.0.0"
    private let port: Int = 8080
    private let eventLoopGroup: MultiThreadedEventLoopGroup
    private let bootstrap: ServerBootstrap
    
    init(context: ModelContext) {
        eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        bootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(.backlog, value: 256)
            .childChannelInitializer({ channel in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
                    channel.pipeline.addHandler(TimeCardServerHandler(context: context))
                }
            })
            .childChannelOption(.socketOption(.so_reuseaddr), value: 1)
    }
    
    func run() async throws {
        let serverChannel = try await bootstrap.bind(host: host, port: port).get()
        try await serverChannel.closeFuture.get()
    }
    
    func shutdown() async throws {
        try await eventLoopGroup.shutdownGracefully()
    }
    
    func shutdown(_ callback: @escaping ((any Error)?) -> Void) {
        eventLoopGroup.shutdownGracefully { error in
            callback(error)
        }
    }
    
    class TimeCardServerHandler: ChannelInboundHandler {
        struct Route {
            let method: HTTPMethod
            let path: [String]
            let handler: (ChannelHandlerContext) throws -> Void
        }
        
        struct HTTPError: Error {
            let status: HTTPResponseStatus
        }
        
        typealias InboundIn = HTTPServerRequestPart
        typealias OutboundOut = HTTPServerResponsePart
        
        private let modelContext: ModelContext
        private var routes: [Route] = []
        private var method: HTTPMethod = .GET
        private var path: String = ""
        private var queryItems: [URLQueryItem]? = nil
        private var requestParams: [String: String] = [:]
        private var requestBody: [String: Any]? = nil
        
        init(context: ModelContext) {
            modelContext = context
            setupRoutes()
        }
        
        private func setupRoutes() {
            routes.append(Route(method: .GET, path: ["timecard", "records"], handler: getRecords))
            routes.append(Route(method: .GET, path: ["timecard", "records", ":id"], handler: getRecord))
            routes.append(Route(method: .POST, path: ["timecard", "records"], handler: insertRecord))
            routes.append(Route(method: .PUT, path: ["timecard", "records", ":id"], handler: updateRecord))
            routes.append(Route(method: .DELETE, path: ["timecard", "records", ":id"], handler: deleteRecord))
            routes.append(Route(method: .GET, path: ["timecard", "breaktime", ":id"], handler: getBreakTime))
        }
        
        private func handleRoutes(context: ChannelHandlerContext) throws {
            typealias Handler = (ChannelHandlerContext) throws -> Void
            var pathMethods: [[String]: [(method: HTTPMethod, handler: Handler)]] = [:]
            for route in routes {
                if pathMethods[route.path] == nil {
                    pathMethods[route.path] = []
                }
                pathMethods[route.path]?.append((route.method, route.handler))
            }
            
            let pathComponents = path.split(separator: "/")
            guard let pathMethod = pathMethods.first(where: { pathComponents.match($0.key) }) else { throw HTTPError(status: .notFound) }
            guard let methodHandlerPair = pathMethod.value.first(where: { $0.method == method }) else { throw HTTPError(status: .methodNotAllowed) }
            
            requestParams = pathComponents.extractParams(rule: pathMethod.key)
            
            try methodHandlerPair.handler(context)
        }
        
        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let part = unwrapInboundIn(data)
            
            switch part {
            case .head(let header):
                method = header.method
                if let url = URLComponents(string: header.uri) {
                    path = url.path
                    queryItems = url.queryItems
                }
                
            case .body(let body):
                requestBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
                
            case .end:
                do {
                    try handleRoutes(context: context)
                } catch let error as HTTPError {
                    handleErrorResponse(status: error.status, context: context)
                } catch {
                    handleErrorResponse(status: .internalServerError, context: context)
                }
            }
        }
        
        private func getRecords(context: ChannelHandlerContext) throws {
            guard let year = Int(queryItems?.first(where: { $0.name == "year" })?.value ?? "") else { throw HTTPError(status: .badRequest) }
            guard let month = Int(queryItems?.first(where: { $0.name == "month" })?.value ?? "") else { throw HTTPError(status: .badRequest)}
            
            let descriptor = FetchDescriptor<TimeRecord>(
                predicate: #Predicate { $0.year == year && $0.month == month },
                sortBy: [.init(\.checkIn)]
            )
            let records = try modelContext.fetch(descriptor)
            
            let json = try JSONEncoder().encode(records)
            let buffer = context.channel.allocator.buffer(data: json)
            handleResponse(buffer: buffer, context: context)
        }
        
        private func getRecord(context: ChannelHandlerContext) throws {
            guard let uuid = UUID(uuidString: requestParams["id"] ?? "") else { throw HTTPError(status: .badRequest) }
            
            let descriptor = FetchDescriptor<TimeRecord>(
                predicate: #Predicate { $0.id == uuid }
            )
            let records = try modelContext.fetch(descriptor)
            if records.isEmpty { throw HTTPError(status: .notFound) }
            
            let json = try JSONEncoder().encode(records)
            let buffer = context.channel.allocator.buffer(data: json)
            handleResponse(buffer: buffer, context: context)
        }
        
        private func insertRecord(context: ChannelHandlerContext) throws {
            guard let requestBody = requestBody else { throw HTTPError(status: .badRequest) }
            guard let checkIn = requestBody["checkIn"] as? Double else { throw HTTPError(status: .badRequest) }
            guard let checkOut = requestBody["checkOut"] as? Double else { throw HTTPError(status: .badRequest) }
            guard let breakTimes = requestBody["breakTimes"] as? [[String: Any]] else { throw HTTPError(status: .badRequest) }
            
            var breakTimeModels: [TimeRecord.BreakTime] = []
            for breakTime in breakTimes {
                guard let start = breakTime["start"] as? Double else { throw HTTPError(status: .badRequest) }
                guard let end = breakTime["end"] as? Double else { throw HTTPError(status: .badRequest) }
                let startDate = Date(timeIntervalSinceReferenceDate: start)
                let endDate = Date(timeIntervalSinceReferenceDate: end)
                let breakTime = TimeRecord.BreakTime(start: startDate, end: endDate)
                breakTimeModels.append(breakTime)
            }
            
            let checkInDate = Date(timeIntervalSinceReferenceDate: checkIn)
            let checkOutDate = Date(timeIntervalSinceReferenceDate: checkOut)
            let record = TimeRecord(year: checkInDate.year, month: checkInDate.month, checkIn: checkInDate, checkOut: checkOutDate)
            record.breakTimes.append(contentsOf: breakTimeModels)
            modelContext.insert(record)
            
            try modelContext.save()
            
            let json = try JSONEncoder().encode([record])
            let buffer = context.channel.allocator.buffer(data: json)
            handleResponse(buffer: buffer, context: context)
        }
        
        private func updateRecord(context: ChannelHandlerContext) throws {
            guard let uuid = UUID(uuidString: requestParams["id"] ?? "") else { throw HTTPError(status: .badRequest) }
            guard let requestBody = requestBody else { throw HTTPError(status: .badRequest) }
            guard let checkIn = requestBody["checkIn"] as? Double else { throw HTTPError(status: .badRequest) }
            guard let checkOut = requestBody["checkOut"] as? Double else { throw HTTPError(status: .badRequest) }
            guard let breakTimes = requestBody["breakTimes"] as? [[String: Any]] else { throw HTTPError(status: .badRequest) }
            
            var breakTimeModels: [TimeRecord.BreakTime] = []
            for breakTime in breakTimes {
                guard let start = breakTime["start"] as? Double else { throw HTTPError(status: .badRequest) }
                guard let end = breakTime["end"] as? Double else { throw HTTPError(status: .badRequest) }
                let startDate = Date(timeIntervalSinceReferenceDate: start)
                let endDate = Date(timeIntervalSinceReferenceDate: end)
                let breakTime = TimeRecord.BreakTime(start: startDate, end: endDate)
                breakTimeModels.append(breakTime)
            }
            
            let descriptor = FetchDescriptor<TimeRecord>(
                predicate: #Predicate { $0.id == uuid }
            )
            let records = try modelContext.fetch(descriptor)
            
            guard let record = records.first else { throw HTTPError(status: .notFound) }
            record.checkIn = Date(timeIntervalSinceReferenceDate: checkIn)
            record.checkOut = Date(timeIntervalSinceReferenceDate: checkOut)
            record.breakTimes.removeAll()
            record.breakTimes.append(contentsOf: breakTimeModels)
            
            try modelContext.save()
            
            let json = try JSONEncoder().encode(records)
            let buffer = context.channel.allocator.buffer(data: json)
            handleResponse(buffer: buffer, context: context)
        }
        
        private func deleteRecord(context: ChannelHandlerContext) throws {
            guard let uuid = UUID(uuidString: requestParams["id"] ?? "") else { throw HTTPError(status: .badRequest) }
            
            let descriptor = FetchDescriptor<TimeRecord>(
                predicate: #Predicate { $0.id == uuid }
            )
            var records = try modelContext.fetch(descriptor)
            
            guard let record = records.first else { throw HTTPError(status: .notFound) }
            modelContext.delete(record)
            records.removeFirst()
            
            try modelContext.save()
            
            let json = try JSONEncoder().encode(records)
            let buffer = context.channel.allocator.buffer(data: json)
            handleResponse(buffer: buffer, context: context)
        }
        
        private func getBreakTime(context: ChannelHandlerContext) throws {
            guard let uuid = UUID(uuidString: requestParams["id"] ?? "") else { throw HTTPError(status: .badRequest) }
            
            let descriptor = FetchDescriptor<TimeRecord.BreakTime>(
                predicate: #Predicate { $0.id == uuid }
            )
            let records = try modelContext.fetch(descriptor)
            if records.isEmpty { throw HTTPError(status: .notFound) }
            
            let json = try JSONEncoder().encode(records)
            let buffer = context.channel.allocator.buffer(data: json)
            handleResponse(buffer: buffer, context: context)
        }
        
        private func handleResponse(buffer: ByteBuffer, context: ChannelHandlerContext) {
            var responseHeaders = HTTPHeaders()
            responseHeaders.add(name: "Content-Type", value: "application/json")
            responseHeaders.add(name: "Content-Length", value: "\(buffer.readableBytes)")
            let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .ok, headers: responseHeaders)
            context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
            context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
            context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
        }
        
        private func handleErrorResponse(status: HTTPResponseStatus, context: ChannelHandlerContext) {
            let buffer = context.channel.allocator.buffer(string: status.description)
            
            var responseHeaders = HTTPHeaders()
            responseHeaders.add(name: "Content-Type", value: "text/plain")
            responseHeaders.add(name: "Content-Length", value: "\(buffer.readableBytes)")
            let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: status, headers: responseHeaders)
            context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
            context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
            context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
        }
    }
}

extension [String.SubSequence] {
    func match(_ target: [String]) -> Bool {
        if self.count != target.count { return false }
        
        for i in 0..<self.count {
            if self[i] == target[i] { continue }
            if target[i].starts(with: ":") { continue }
            return false
        }
        
        return true
    }
    
    func extractParams(rule: [String]) -> [String: String] {
        var params: [String: String] = [:]
        if self.count != rule.count { return params }
        
        for i in 0..<self.count {
            if !rule[i].starts(with: ":") { continue }
            let key = String(rule[i].dropFirst())
            params[key] = String(self[i])
        }
        
        return params
    }
}
