//
//  TimeCardServer.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/28.
//

import Foundation
import NIO
import NIOFoundationCompat
import NIOHTTP1

class TimeCardServer {
    private let host: String = "0.0.0.0"
    private let port: Int = 8080
    private let eventLoopGroup: MultiThreadedEventLoopGroup
    private let bootstrap: ServerBootstrap
    
    init(_ repository: TimeRecordRepository) {
        eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        bootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(.backlog, value: 256)
            .childChannelInitializer({ channel in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
                    channel.pipeline.addHandler(TimeCardServerHandler(repository))
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
        
        private let repository: TimeRecordRepository
        private var routes: [Route] = []
        private var method: HTTPMethod = .GET
        private var path: String = ""
        private var queryItems: [URLQueryItem]? = nil
        private var requestParams: [String: String] = [:]
        private var requestBody: [String: Any]? = nil
        
        init(_ repository: TimeRecordRepository) {
            self.repository = repository
            setupRoutes()
        }
        
        private func setupRoutes() {
            routes.append(Route(method: .GET, path: ["timecard", "records"], handler: getRecords))
            routes.append(Route(method: .GET, path: ["timecard", "records", ":id"], handler: getRecord))
            routes.append(Route(method: .POST, path: ["timecard", "records"], handler: insertRecord))
            routes.append(Route(method: .PATCH, path: ["timecard", "records", ":id"], handler: updateRecord))
            routes.append(Route(method: .DELETE, path: ["timecard", "records", ":id"], handler: deleteRecord))
            routes.append(Route(method: .GET, path: ["timecard", "breaktimes", ":id"], handler: getBreakTime))
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
            
            let records = try repository.getRecords(year: year, month: month)
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let json = try encoder.encode(records)
            let buffer = context.channel.allocator.buffer(data: json)
            handleResponse(buffer: buffer, context: context)
        }
        
        private func getRecord(context: ChannelHandlerContext) throws {
            guard let uuid = UUID(uuidString: requestParams["id"] ?? "") else { throw HTTPError(status: .badRequest) }
            
            guard let record = try repository.getRecord(id: uuid) else { throw HTTPError(status: .notFound) }
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let json = try encoder.encode([record])
            let buffer = context.channel.allocator.buffer(data: json)
            handleResponse(buffer: buffer, context: context)
        }
        
        private func insertRecord(context: ChannelHandlerContext) throws {
            guard let requestBody = requestBody else { throw HTTPError(status: .badRequest) }
            guard let checkIn = requestBody["checkIn"] as? String else { throw HTTPError(status: .badRequest) }
            guard let checkOut = requestBody["checkOut"] as? String else { throw HTTPError(status: .badRequest) }
            guard let checkInDate = try? Date(checkIn, strategy: .iso8601) else { throw HTTPError(status: .badRequest) }
            guard let checkOutDate = try? Date(checkOut, strategy: .iso8601) else { throw HTTPError(status: .badRequest) }
            guard let breakTimes = requestBody["breakTimes"] as? [[String: Any]] else { throw HTTPError(status: .badRequest) }
            
            var breakTimeModels: [TimeRecord.BreakTime] = []
            for breakTime in breakTimes {
                guard let start = breakTime["start"] as? String else { throw HTTPError(status: .badRequest) }
                guard let end = breakTime["end"] as? String else { throw HTTPError(status: .badRequest) }
                guard let startDate = try? Date(start, strategy: .iso8601) else { throw HTTPError(status: .badRequest) }
                guard let endDate = try? Date(end, strategy: .iso8601) else { throw HTTPError(status: .badRequest) }
                let breakTime = TimeRecord.BreakTime(start: startDate, end: endDate)
                breakTimeModels.append(breakTime)
            }
            
            let record = TimeRecord(
                checkIn: checkInDate,
                checkOut: checkOutDate,
                breakTimes: breakTimeModels
            )
            try repository.insert(record)
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let json = try encoder.encode([record])
            let buffer = context.channel.allocator.buffer(data: json)
            handleResponse(buffer: buffer, context: context)
        }
        
        private func updateRecord(context: ChannelHandlerContext) throws {
            guard let uuid = UUID(uuidString: requestParams["id"] ?? "") else { throw HTTPError(status: .badRequest) }
            guard let requestBody = requestBody else { throw HTTPError(status: .badRequest) }
            guard let checkIn = requestBody["checkIn"] as? String else { throw HTTPError(status: .badRequest) }
            guard let checkOut = requestBody["checkOut"] as? String else { throw HTTPError(status: .badRequest) }
            guard let checkInDate = try? Date(checkIn, strategy: .iso8601) else { throw HTTPError(status: .badRequest) }
            guard let checkOutDate = try? Date(checkOut, strategy: .iso8601) else { throw HTTPError(status: .badRequest) }
            guard let breakTimes = requestBody["breakTimes"] as? [[String: Any]] else { throw HTTPError(status: .badRequest) }
            
            var breakTimeModels: [TimeRecord.BreakTime] = []
            for breakTime in breakTimes {
                guard let start = breakTime["start"] as? String else { throw HTTPError(status: .badRequest) }
                guard let end = breakTime["end"] as? String else { throw HTTPError(status: .badRequest) }
                guard let startDate = try? Date(start, strategy: .iso8601) else { throw HTTPError(status: .badRequest) }
                guard let endDate = try? Date(end, strategy: .iso8601) else { throw HTTPError(status: .badRequest) }
                let breakTime = TimeRecord.BreakTime(start: startDate, end: endDate)
                breakTimeModels.append(breakTime)
            }
            
            guard var record = try repository.getRecord(id: uuid) else { throw HTTPError(status: .notFound) }
            record.checkIn = checkInDate
            record.checkOut = checkOutDate
            record.breakTimes = breakTimeModels
            try repository.update(record)
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let json = try encoder.encode([record])
            let buffer = context.channel.allocator.buffer(data: json)
            handleResponse(buffer: buffer, context: context)
        }
        
        private func deleteRecord(context: ChannelHandlerContext) throws {
            guard let uuid = UUID(uuidString: requestParams["id"] ?? "") else { throw HTTPError(status: .badRequest) }
            
            guard let record = try repository.getRecord(id: uuid) else { throw HTTPError(status: .notFound) }
            try repository.delete(record)
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let records: [TimeRecord] = []
            let json = try encoder.encode(records)
            let buffer = context.channel.allocator.buffer(data: json)
            handleResponse(buffer: buffer, context: context)
        }
        
        private func getBreakTime(context: ChannelHandlerContext) throws {
            guard let uuid = UUID(uuidString: requestParams["id"] ?? "") else { throw HTTPError(status: .badRequest) }
            
            guard let record = try repository.getBreakTime(id: uuid) else { throw HTTPError(status: .notFound) }
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let json = try encoder.encode([record])
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
