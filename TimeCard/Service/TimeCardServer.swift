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
import OSLog

class TimeCardServer {
    private let host: String = "0.0.0.0"
    private let port: Int = 8080
    private let eventLoopGroup: MultiThreadedEventLoopGroup
    private let bootstrap: ServerBootstrap
    private let timeRepository: TimeRecordRepository
    private let userRepository: UserRepository
    #if DEBUG
    private let logger = Logger(subsystem: "TimeCard.Debug", category: "TimeCardServer")
    #else
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeCard", category: "TimeCardServer")
    #endif

    init(_ timeRepository: TimeRecordRepository, _ userRepository: UserRepository) {
        eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        bootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(.backlog, value: 256)
            .childChannelOption(.socketOption(.so_reuseaddr), value: 1)
        
        self.timeRepository = timeRepository
        self.userRepository = userRepository
    }
    
    func run() async throws {
        let serverChannel = try await bootstrap.bind(host: host, port: port) { channel in
            channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
                channel.eventLoop.makeCompletedFuture {
                    try NIOAsyncChannel(
                        wrappingChannelSynchronously: channel,
                        configuration: NIOAsyncChannel.Configuration(
                            inboundType: HTTPServerRequestPart.self,
                            outboundType: HTTPServerResponsePart.self
                        )
                    )
                }
            }
        }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            try await serverChannel.executeThenClose { inbound, _ in
                for try await clientChannel in inbound {
                    group.addTask {
                        do {
                            let handler = TimeCardServerHandler(clientChannel, self.timeRepository, self.userRepository)
                            try await handler.handleRequests()
                        } catch {
                            self.logger.error("\(error.localizedDescription, privacy: .public)")
                        }
                    }
                }
            }
        }
    }
    
    func shutdown() async throws {
        try await eventLoopGroup.shutdownGracefully()
    }
    
    func shutdown(_ callback: @escaping ((any Error)?) -> Void) {
        eventLoopGroup.shutdownGracefully { error in
            callback(error)
        }
    }
    
    class TimeCardServerHandler {
        typealias Outbound = NIOAsyncChannelOutboundWriter<HTTPServerResponsePart>
        
        struct Route {
            let method: HTTPMethod
            let path: [String]
            let handler: (Outbound) async throws -> Void
        }
        
        struct HTTPError: Error {
            let status: HTTPResponseStatus
        }
        
        private let channel: NIOAsyncChannel<HTTPServerRequestPart, HTTPServerResponsePart>
        private let timeRepository: TimeRecordRepository
        private let userRepository: UserRepository
        private var routes: [Route] = []
        private var method: HTTPMethod = .GET
        private var path: String = ""
        private var queryItems: [URLQueryItem]? = nil
        private var requestParams: [String: String] = [:]
        private var requestHeaders: HTTPHeaders? = nil
        private var requestBody: [String: Any]? = nil
        
        init(_ channel: NIOAsyncChannel<HTTPServerRequestPart, HTTPServerResponsePart>, _ timeRepository: TimeRecordRepository, _ userRepository: UserRepository) {
            self.channel = channel
            self.timeRepository = timeRepository
            self.userRepository = userRepository
            
            setupRoutes()
        }
        
        private func setupRoutes() {
            routes.append(Route(method: .GET, path: ["timecard", "records"], handler: getRecords))
            routes.append(Route(method: .GET, path: ["timecard", "records", ":id"], handler: getRecord))
            routes.append(Route(method: .POST, path: ["timecard", "records"], handler: insertRecord))
            routes.append(Route(method: .PATCH, path: ["timecard", "records", ":id"], handler: updateRecord))
            routes.append(Route(method: .DELETE, path: ["timecard", "records", ":id"], handler: deleteRecord))
            routes.append(Route(method: .GET, path: ["timecard", "breaktimes", ":id"], handler: getBreakTime))
            routes.append(Route(method: .POST, path: ["timecard", "auth", "register"], handler: registerUser))
            routes.append(Route(method: .POST, path: ["timecard", "auth", "verify"], handler: verifyUser))
            routes.append(Route(method: .POST, path: ["timecard", "auth", "login"], handler: login))
            routes.append(Route(method: .POST, path: ["timecard", "auth", "refresh"], handler: refreshToken))
        }
        
        func handleRequests() async throws {
            try await channel.executeThenClose { inbound, outbound in
                for try await requestPart in inbound {
                    try await channelRead(requestPart, outbound)
                    
                    if case .end = requestPart {
                        break
                    }
                }
            }
        }
        
        private func handleRoutes(_ outbound: Outbound) async throws {
            typealias Handler = (Outbound) async throws -> Void
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
            
            try await methodHandlerPair.handler(outbound)
        }
        
        private func channelRead(_ inbound: HTTPServerRequestPart, _ outbound: Outbound) async throws {
            switch inbound {
            case .head(let header):
                method = header.method
                requestHeaders = header.headers
                if let url = URLComponents(string: header.uri) {
                    path = url.path
                    queryItems = url.queryItems
                }
                
            case .body(let body):
                requestBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
                
            case .end:
                do {
                    try await handleRoutes(outbound)
                } catch let error as HTTPError {
                    try await handleErrorResponse(status: error.status, outbound: outbound)
                } catch {
                    try await handleErrorResponse(status: .internalServerError, outbound: outbound)
                }
            }
        }
        
        private func getRecords(outbound: Outbound) async throws {
            guard validateToken() else { throw HTTPError(status: .unauthorized) }
            
            guard let year = Int(queryItems?.first(where: { $0.name == "year" })?.value ?? "") else { throw HTTPError(status: .badRequest) }
            guard let month = Int(queryItems?.first(where: { $0.name == "month" })?.value ?? "") else { throw HTTPError(status: .badRequest)}
            
            let records = try timeRepository.getRecords(year: year, month: month)
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let json = try encoder.encode(records)
            let buffer = channel.channel.allocator.buffer(data: json)
            try await handleResponse(response: buffer, outbound: outbound)
        }
        
        private func getRecord(outbound: Outbound) async throws {
            guard validateToken() else { throw HTTPError(status: .unauthorized) }
            
            guard let uuid = UUID(uuidString: requestParams["id"] ?? "") else { throw HTTPError(status: .badRequest) }
            
            guard let record = try timeRepository.getRecord(id: uuid) else { throw HTTPError(status: .notFound) }
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let json = try encoder.encode([record])
            let buffer = channel.channel.allocator.buffer(data: json)
            try await handleResponse(response: buffer, outbound: outbound)
        }
        
        private func insertRecord(outbound: Outbound) async throws {
            guard validateToken() else { throw HTTPError(status: .unauthorized) }
            
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
            try timeRepository.insert(record)
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let json = try encoder.encode([record])
            let buffer = channel.channel.allocator.buffer(data: json)
            try await handleResponse(response: buffer, outbound: outbound)
        }
        
        private func updateRecord(outbound: Outbound) async throws {
            guard validateToken() else { throw HTTPError(status: .unauthorized) }
            
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
            
            guard var record = try timeRepository.getRecord(id: uuid) else { throw HTTPError(status: .notFound) }
            record.checkIn = checkInDate
            record.checkOut = checkOutDate
            record.breakTimes = breakTimeModels
            try timeRepository.update(record)
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let json = try encoder.encode([record])
            let buffer = channel.channel.allocator.buffer(data: json)
            try await handleResponse(response: buffer, outbound: outbound)
        }
        
        private func deleteRecord(outbound: Outbound) async throws {
            guard validateToken() else { throw HTTPError(status: .unauthorized) }
            
            guard let uuid = UUID(uuidString: requestParams["id"] ?? "") else { throw HTTPError(status: .badRequest) }
            
            guard let record = try timeRepository.getRecord(id: uuid) else { throw HTTPError(status: .notFound) }
            try timeRepository.delete(record)
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let records: [TimeRecord] = []
            let json = try encoder.encode(records)
            let buffer = channel.channel.allocator.buffer(data: json)
            try await handleResponse(response: buffer, outbound: outbound)
        }
        
        private func getBreakTime(outbound: Outbound) async throws {
            guard validateToken() else { throw HTTPError(status: .unauthorized) }
            
            guard let uuid = UUID(uuidString: requestParams["id"] ?? "") else { throw HTTPError(status: .badRequest) }
            
            guard let record = try timeRepository.getBreakTime(id: uuid) else { throw HTTPError(status: .notFound) }
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let json = try encoder.encode([record])
            let buffer = channel.channel.allocator.buffer(data: json)
            try await handleResponse(response: buffer, outbound: outbound)
        }
        
        private func registerUser(outbound: Outbound) async throws {
            guard let requestBody = requestBody else { throw HTTPError(status: .badRequest) }
            guard let mail = requestBody["mail"] as? String else { throw HTTPError(status: .badRequest) }
            guard let password = requestBody["password"] as? String else { throw HTTPError(status: .badRequest) }
            
            do {
                try await userRepository.register(mail: mail, password: password)
                
                try await handleResponse(status: .created, outbound: outbound)
            } catch _ as DefaultUserRepository.RegisterError {
                try await handleErrorResponse(status: .unprocessableEntity, outbound: outbound)
            }
        }
        
        private func verifyUser(outbound: Outbound) async throws {
            guard let requestBody = requestBody else { throw HTTPError(status: .badRequest) }
            guard let mail = requestBody["mail"] as? String else { throw HTTPError(status: .badRequest) }
            guard let verifyCode = requestBody["verifyCode"] as? String else { throw HTTPError(status: .badRequest) }
            
            do {
                let token = try userRepository.verify(mail: mail, verifyCode: verifyCode)
                
                let encoder = JSONEncoder()
                let json = try encoder.encode(token)
                let buffer = channel.channel.allocator.buffer(data: json)
                try await handleResponse(response: buffer, outbound: outbound)
            } catch let error as DefaultUserRepository.VerifyError {
                switch error {
                case .exceedAttempts:
                    try await handleErrorResponse(status: .tooManyRequests, outbound: outbound)
                default:
                    try await handleErrorResponse(status: .unprocessableEntity, outbound: outbound)
                }
            }
        }
        
        private func login(outbound: Outbound) async throws {
            guard let requestBody = requestBody else { throw HTTPError(status: .badRequest) }
            guard let mail = requestBody["mail"] as? String else { throw HTTPError(status: .badRequest) }
            guard let password = requestBody["password"] as? String else { throw HTTPError(status: .badRequest) }
            
            do {
                let token = try await userRepository.login(mail: mail, password: password)
                
                let encoder = JSONEncoder()
                let json = try encoder.encode(token)
                let buffer = channel.channel.allocator.buffer(data: json)
                try await handleResponse(response: buffer, outbound: outbound)
            } catch _ as DefaultUserRepository.LoginError {
                try await handleErrorResponse(status: .unauthorized, outbound: outbound)
            }
        }
        
        private func refreshToken(outbound: Outbound) async throws {
            guard let requestBody = requestBody else { throw HTTPError(status: .badRequest) }
            guard let token = requestBody["refreshToken"] as? String else { throw HTTPError(status: .badRequest) }
            
            do {
                let token = try userRepository.refresh(token: token)
                
                let encoder = JSONEncoder()
                let json = try encoder.encode(token)
                let buffer = channel.channel.allocator.buffer(data: json)
                try await handleResponse(response: buffer, outbound: outbound)
            } catch _ as DefaultUserRepository.RefreshError {
                try await handleErrorResponse(status: .unauthorized, outbound: outbound)
            }
        }
        
        private func handleResponse(response: ByteBuffer? = nil, status: HTTPResponseStatus = .ok, outbound: Outbound) async throws {
            let buffer = response ?? channel.channel.allocator.buffer(string: status.description)
            var responseHeaders = HTTPHeaders()
            responseHeaders.add(name: "Content-Type", value: "application/json")
            responseHeaders.add(name: "Content-Length", value: "\(buffer.readableBytes)")
            let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: status, headers: responseHeaders)
            try await outbound.write(.head(responseHead))
            try await outbound.write(.body(.byteBuffer(buffer)))
            try await outbound.write(.end(nil))
        }
        
        private func handleErrorResponse(status: HTTPResponseStatus, outbound: Outbound) async throws {
            let buffer = channel.channel.allocator.buffer(string: status.description)
            
            var responseHeaders = HTTPHeaders()
            responseHeaders.add(name: "Content-Type", value: "text/plain")
            responseHeaders.add(name: "Content-Length", value: "\(buffer.readableBytes)")
            if status == .unauthorized {
                responseHeaders.add(name: "WWW-Authenticate", value: "Bearer")
            }
            let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: status, headers: responseHeaders)
            try await outbound.write(.head(responseHead))
            try await outbound.write(.body(.byteBuffer(buffer)))
            try await outbound.write(.end(nil))
        }
        
        private func validateToken() -> Bool {
            guard let value = requestHeaders?.first(name: "Authorization") else { return false }
            
            let values = value.split(whereSeparator: { $0.isWhitespace })
            guard values.count == 2 else { return false }
            guard values[0].lowercased() == "bearer" else { return false }
            
            return userRepository.verifyLogin(token: String(values[1]))
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
