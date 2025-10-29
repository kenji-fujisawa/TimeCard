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
    
    private class TimeCardServerHandler: ChannelInboundHandler {
        typealias InboundIn = HTTPServerRequestPart
        typealias OutboundOut = HTTPServerResponsePart
        
        private let modelContext: ModelContext
        private var method: HTTPMethod = .GET
        private var path: String = ""
        private var requestParams: [URLQueryItem]? = nil
        
        init(context: ModelContext) {
            modelContext = context
        }
        
        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let part = unwrapInboundIn(data)
            
            switch part {
            case .head(let header):
                method = header.method
                if let url = URLComponents(string: header.uri) {
                    path = url.path
                    requestParams = url.queryItems
                }
                
            case .body: break
                
            case .end:
                do {
                    switch (method, path) {
                    case (.GET, "/timecard/records"):
                        try handleRecords(context: context)
                    default:
                        handleNotFound(context: context)
                    }
                } catch {
                    handleInternalError(context: context)
                }
            }
        }
        
        private func handleRecords(context: ChannelHandlerContext) throws {
            let year = Int(requestParams?.first(where: { $0.name == "year" })?.value ?? "0") ?? 0
            let month = Int(requestParams?.first(where: { $0.name == "month" })?.value ?? "0") ?? 0
            
            let descriptor = FetchDescriptor<TimeRecord>(
                predicate: #Predicate { $0.year == year && $0.month == month },
                sortBy: [.init(\.checkIn)]
            )
            let records = try modelContext.fetch(descriptor)
            
            let encoder = JSONEncoder()
            let json = try encoder.encode(records)
            
            let buffer = context.channel.allocator.buffer(buffer: ByteBuffer(data: json))
            
            var responseHeaders = HTTPHeaders()
            responseHeaders.add(name: "Content-Type", value: "application/json")
            responseHeaders.add(name: "Content-Length", value: "\(buffer.readableBytes)")
            let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .ok, headers: responseHeaders)
            context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
            context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
            context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
        }
        
        private func handleNotFound(context: ChannelHandlerContext) {
            let buffer = context.channel.allocator.buffer(string: "Not Found")
            
            var responseHeaders = HTTPHeaders()
            responseHeaders.add(name: "Content-Type", value: "text/plain")
            responseHeaders.add(name: "Content-Length", value: "\(buffer.readableBytes)")
            let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .notFound, headers: responseHeaders)
            context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
            context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
            context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
        }
        
        private func handleInternalError(context: ChannelHandlerContext) {
            let buffer = context.channel.allocator.buffer(string: "Internal Server Error")
            
            var responseHeaders = HTTPHeaders()
            responseHeaders.add(name: "Content-Type", value: "text/plain")
            responseHeaders.add(name: "Content-Length", value: "\(buffer.readableBytes)")
            let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .internalServerError, headers: responseHeaders)
            context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
            context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
            context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
        }
    }
}
