//
//  TimeCardServerTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2025/10/30.
//

import Foundation
import NIO
import NIOHTTP1
import NIOFoundationCompat
import SwiftData
import Testing

@testable @preconcurrency import TimeCard

struct TimeCardServerTests {

    private var records: [TimeRecord] = []
    private var container: ModelContainer!
    private var context: ModelContext!
    private var formatter: DateFormatter
    private var verifyCodeSender: FakeVerifyCodeSender!
    private var timeRepository: TimeRecordRepository!
    private var userRepository: UserRepository!
    private var responseHead: HTTPResponseHead? = nil
    private var responseBody: Any? = nil
    private var responseEnd: HTTPHeaders? = nil
    
    init() async throws {
        formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        try setupContext()
        setupRepository()
    }
    
    private mutating func setupContext() throws {
        let schema = Schema([LocalTimeRecord.self, LocalUser.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
        
        var record = LocalTimeRecord(
            year: 2025,
            month: 10,
            checkIn: formatter.date(from: "2025-10-15 09:30:00"),
            checkOut: formatter.date(from: "2025-10-15 17:00:00"),
            breakTimes: [
                LocalTimeRecord.BreakTime(
                    start: formatter.date(from: "2025-10-15 12:15:00"),
                    end: formatter.date(from: "2025-10-15 12:45:00")
                )
            ]
        )
        context.insert(record)
        records.append(record.asTimeRecord())
        
        record = LocalTimeRecord(
            year: 2025,
            month: 10,
            checkIn: formatter.date(from: "2025-10-18 10:00:00"),
            checkOut: formatter.date(from: "2025-10-18 18:30:00"),
            breakTimes: [
                LocalTimeRecord.BreakTime(
                    start: formatter.date(from: "2025-10-18 12:30:00"),
                    end: formatter.date(from: "2025-10-15 13:00:00")
                ),
                LocalTimeRecord.BreakTime(
                    start: formatter.date(from: "2025-10-18 17:30:00"),
                    end: formatter.date(from: "2025-10-15 18:00:00")
                )
            ]
        )
        context.insert(record)
        records.append(record.asTimeRecord())
    }
    
    private mutating func setupRepository() {
        let source = DefaultLocalDataSource(context)
        let passwordHasher = FakePasswordHasher()
        let verifyCodeSender = FakeVerifyCodeSender()
        let timeRepository = DefaultTimeRecordRepository(source)
        let userRepository = DefaultUserRepository(source, verifyCodeSender, passwordHasher)
        
        self.verifyCodeSender = verifyCodeSender
        self.timeRepository = timeRepository
        self.userRepository = userRepository
    }
    
    private func publishToken() throws -> String {
        let userId = UUID()
        let user = User(id: userId, mail: "mail@test.com", password: "password")
        context.insert(user.asLocal())
        return try JWT.encode(sub: userId.uuidString, exp: Date(timeIntervalSinceNow: 100))
    }
    
    private mutating func runTest(method: HTTPMethod, uri: String, token: String = "", body: String = "") async throws {
        let channel = NIOAsyncTestingChannel()
        let asyncChannel = try await channel.testingEventLoop.submit {
            try NIOAsyncChannel(
                wrappingChannelSynchronously: channel,
                configuration: NIOAsyncChannel.Configuration(
                    inboundType: HTTPServerRequestPart.self,
                    outboundType: HTTPServerResponsePart.self
                )
            )
        }.get()
        
        let handler = TimeCardServer.TimeCardServerHandler(asyncChannel, timeRepository, userRepository)
        
        Task {
            try await handler.handleRequests()
        }
        
        let headers = HTTPHeaders([("Authorization", "Bearer \(token)")])
        let head = HTTPRequestHead(version: .init(major: 1, minor: 1), method: method, uri: uri, headers: headers)
        let body = channel.allocator.buffer(string: body)
        let requestHead = HTTPServerRequestPart.head(head)
        let requestBody = HTTPServerRequestPart.body(body)
        let requestEnd = HTTPServerRequestPart.end(nil)
        try await channel.writeInbound(requestHead)
        try await channel.writeInbound(requestBody)
        try await channel.writeInbound(requestEnd)
        
        let responseHead = try await channel.waitForOutboundWrite(as: HTTPServerResponsePart.self)
        let responseBody = try await channel.waitForOutboundWrite(as: HTTPServerResponsePart.self)
        let responseEnd = try await channel.waitForOutboundWrite(as: HTTPServerResponsePart.self)
        if case .head(let head) = responseHead {
            self.responseHead = head
        }
        
        if case .body(.byteBuffer(let body)) = responseBody {
            self.responseBody = try? JSONSerialization.jsonObject(with: body)
        }
        
        if case .end(let end) = responseEnd {
            self.responseEnd = end
        }
    }
    
    @Test mutating func testGetRecords() async throws {
        try await runTest(method: .GET, uri: "/timecard/records?year=2025&month=10", token: publishToken())
        #expect(responseHead?.status == .ok)
        #expect(responseHead?.headers.first(name: "Content-Type") == "application/json")
        
        let responseBody = self.responseBody as? [[String: Any]]
        #expect(responseBody?.count == records.count)
        for i in 0..<records.count {
            let dict = responseBody?[i]
            let record = records[i]
            #expect(dict?["id"] as? String == record.id.uuidString)
            #expect(dict?["checkIn"] as? String == record.checkIn?.ISO8601Format())
            #expect(dict?["checkOut"] as? String == record.checkOut?.ISO8601Format())
            
            let breakTimes = dict?["breakTimes"] as? [[String: Any]]
            #expect(breakTimes?.count == record.breakTimes.count)
            for i in 0..<record.breakTimes.count {
                let dict = breakTimes?[i]
                let breakTime = record.breakTimes[i]
                #expect(dict?["id"] as? String == breakTime.id.uuidString)
                #expect(dict?["start"] as? String == breakTime.start?.ISO8601Format())
                #expect(dict?["end"] as? String == breakTime.end?.ISO8601Format())
            }
        }
    }

    @Test mutating func testGetRecords_missingParameter() async throws {
        try await runTest(method: .GET, uri: "/timecard/records", token: publishToken())
        #expect(responseHead?.status == .badRequest)
    }
    
    @Test mutating func testGetRecords_wrongMethod() async throws {
        try await runTest(method: .ACL, uri: "/timecard/records?year=2025&month=10", token: publishToken())
        #expect(responseHead?.status == .methodNotAllowed)
    }
    
    @Test mutating func testGetRecords_unauthorized() async throws {
        try await runTest(method: .GET, uri: "/timecard/records?year=2025&month=10")
        #expect(responseHead?.status == .unauthorized)
        #expect(responseHead?.headers.first(name: "WWW-Authenticate") == "Bearer")
    }

    @Test mutating func testGetRecord() async throws {
        let uri = "/timecard/records/\(records[1].id.uuidString)"
        try await runTest(method: .GET, uri: uri, token: publishToken())
        #expect(responseHead?.status == .ok)
        #expect(responseHead?.headers.first(name: "Content-Type") == "application/json")
        
        let responseBody = self.responseBody as? [[String: Any]]
        #expect(responseBody?.count == 1)
        
        let dict = responseBody?[0]
        let record = records[1]
        #expect(dict?["id"] as? String == record.id.uuidString)
        #expect(dict?["checkIn"] as? String == record.checkIn?.ISO8601Format())
        #expect(dict?["checkOut"] as? String == record.checkOut?.ISO8601Format())
        
        let breakTimes = dict?["breakTimes"] as? [[String: Any]]
        #expect(breakTimes?.count == record.breakTimes.count)
        for i in 0..<record.breakTimes.count {
            let dict = breakTimes?[i]
            let breakTime = record.breakTimes[i]
            #expect(dict?["id"] as? String == breakTime.id.uuidString)
            #expect(dict?["start"] as? String == breakTime.start?.ISO8601Format())
            #expect(dict?["end"] as? String == breakTime.end?.ISO8601Format())
        }
    }
    
    @Test mutating func testGetRecord_wrongId() async throws {
        let uri = "/timecard/records/\(UUID().uuidString)"
        try await runTest(method: .GET, uri: uri, token: publishToken())
        #expect(responseHead?.status == .notFound)
    }
    
    @Test mutating func testGetRecord_tooManyPath() async throws {
        let uri = "/timecard/records/\(records[1].id.uuidString)/redundant"
        try await runTest(method: .GET, uri: uri, token: publishToken())
        #expect(responseHead?.status == .notFound)
    }
    
    @Test mutating func testGetRecord_unauthorized() async throws {
        let uri = "/timecard/records/\(records[1].id.uuidString)"
        try await runTest(method: .GET, uri: uri)
        #expect(responseHead?.status == .unauthorized)
        #expect(responseHead?.headers.first(name: "WWW-Authenticate") == "Bearer")
    }
    
    @Test mutating func testPostRecord() async throws {
        let uri = "/timecard/records"
        let checkIn = formatter.date(from: "2025-10-20 09:00:00")?.ISO8601Format() ?? ""
        let checkOut = formatter.date(from: "2025-10-20 17:00:00")?.ISO8601Format() ?? ""
        let start1 = formatter.date(from: "2025-10-20 12:00:00")?.ISO8601Format() ?? ""
        let end1 = formatter.date(from: "2025-10-20 13:00:00")?.ISO8601Format() ?? ""
        let start2 = formatter.date(from: "2025-10-20 15:00:00")?.ISO8601Format() ?? ""
        let end2 = formatter.date(from: "2025-10-20 15:30:00")?.ISO8601Format() ?? ""
        let body = """
            {
                "checkIn":      "\(checkIn)",
                "checkOut":     "\(checkOut)",
                "breakTimes": [{
                    "start":    "\(start1)",
                    "end":      "\(end1)"
                }, {
                    "start":    "\(start2)",
                    "end":      "\(end2)"
                }]
            }
            """
        try await runTest(method: .POST, uri: uri, token: publishToken(), body: body)
        #expect(responseHead?.status == .ok)
        #expect(responseHead?.headers.first(name: "Content-Type") == "application/json")
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.year == 2025 && $0.month == 10 },
            sortBy: [.init(\.checkIn)]
        )
        let records = try context.fetch(descriptor)
        records.forEach { $0.breakTimes.sort { $0.start ?? .distantPast < $1.start ?? .distantPast }}
        #expect(records.count == 3)
        #expect(records[0].checkIn?.day == 15)
        #expect(records[1].checkIn?.day == 18)
        #expect(records[2].checkIn?.ISO8601Format() == checkIn)
        #expect(records[2].checkOut?.ISO8601Format() == checkOut)
        #expect(records[2].breakTimes.count == 2)
        #expect(records[2].breakTimes[0].start?.ISO8601Format() == start1)
        #expect(records[2].breakTimes[0].end?.ISO8601Format() == end1)
        #expect(records[2].breakTimes[1].start?.ISO8601Format() == start2)
        #expect(records[2].breakTimes[1].end?.ISO8601Format() == end2)
        
        let responseBody = self.responseBody as? [[String: Any]]
        #expect(responseBody?.count == 1)
        
        let dict = responseBody?[0]
        #expect(dict?["id"] as? String != "")
        #expect(dict?["checkIn"] as? String == checkIn)
        #expect(dict?["checkOut"] as? String == checkOut)
        
        var breakTimes = dict?["breakTimes"] as? [[String: Any]]
        breakTimes?.sort(by: { $0["start"] as? Double ?? 0 < $1["start"] as? Double ?? 0 })
        
        let record = records[2]
        #expect(breakTimes?.count == record.breakTimes.count)
        for i in 0..<record.breakTimes.count {
            let dict = breakTimes?[i]
            let breakTime = record.breakTimes[i]
            #expect(dict?["id"] as? String == breakTime.id.uuidString)
            #expect(dict?["start"] as? String == breakTime.start?.ISO8601Format())
            #expect(dict?["end"] as? String == breakTime.end?.ISO8601Format())
        }
    }
    
    @Test mutating func testPostRecord_wrongBody() async throws {
        let uri = "/timecard/records"
        let checkIn = formatter.date(from: "2025-10-20 09:00:00")?.ISO8601Format() ?? ""
        let checkOut = formatter.date(from: "2025-10-20 17:00:00")?.ISO8601Format() ?? ""
        let body = """
            {
                "checkIn":  "\(checkIn)",
                "checkOut": "\(checkOut)",
                "wrongKey": "wrongValue"
            }
            """
        try await runTest(method: .POST, uri: uri, token: publishToken(), body: body)
        #expect(responseHead?.status == .badRequest)
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.year == 2025 && $0.month == 10 },
            sortBy: [.init(\.checkIn)]
        )
        let records = try context.fetch(descriptor)
        #expect(records.count == 2)
        #expect(records[0].checkIn?.day == 15)
        #expect(records[1].checkIn?.day == 18)
    }
    
    @Test mutating func testPostRecord_missingParameter() async throws {
        let uri = "/timecard/records"
        let checkIn = formatter.date(from: "2025-10-20 09:00:00")?.ISO8601Format() ?? ""
        let body = """
            {
                "checkIn":  "\(checkIn)"
            }
            """
        try await runTest(method: .POST, uri: uri, token: publishToken(), body: body)
        #expect(responseHead?.status == .badRequest)
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.year == 2025 && $0.month == 10 },
            sortBy: [.init(\.checkIn)]
        )
        let records = try context.fetch(descriptor)
        #expect(records.count == 2)
        #expect(records[0].checkIn?.day == 15)
        #expect(records[1].checkIn?.day == 18)
    }
    
    @Test mutating func testPostRecord_tooManyPath() async throws {
        let uri = "/timecard/records/\(UUID().uuidString)"
        let checkIn = formatter.date(from: "2025-10-20 09:00:00")?.ISO8601Format() ?? ""
        let checkOut = formatter.date(from: "2025-10-20 17:00:00")?.ISO8601Format() ?? ""
        let start1 = formatter.date(from: "2025-10-20 12:00:00")?.ISO8601Format() ?? ""
        let end1 = formatter.date(from: "2025-10-20 13:00:00")?.ISO8601Format() ?? ""
        let start2 = formatter.date(from: "2025-10-20 15:00:00")?.ISO8601Format() ?? ""
        let end2 = formatter.date(from: "2025-10-20 15:30:00")?.ISO8601Format() ?? ""
        let body = """
            {
                "checkIn":      "\(checkIn)",
                "checkOut":     "\(checkOut)",
                "breakTimes": [{
                    "start":    "\(start1)",
                    "end":      "\(end1)"
                }, {
                    "start":    "\(start2)",
                    "end":      "\(end2)"
                }]
            }
            """
        try await runTest(method: .POST, uri: uri, token: publishToken(), body: body)
        #expect(responseHead?.status == .methodNotAllowed)
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.year == 2025 && $0.month == 10 },
            sortBy: [.init(\.checkIn)]
        )
        let records = try context.fetch(descriptor)
        #expect(records.count == 2)
        #expect(records[0].checkIn?.day == 15)
        #expect(records[1].checkIn?.day == 18)
    }
    
    @Test mutating func testPostRecord_unauthorized() async throws {
        let uri = "/timecard/records"
        let checkIn = formatter.date(from: "2025-10-20 09:00:00")?.ISO8601Format() ?? ""
        let checkOut = formatter.date(from: "2025-10-20 17:00:00")?.ISO8601Format() ?? ""
        let start1 = formatter.date(from: "2025-10-20 12:00:00")?.ISO8601Format() ?? ""
        let end1 = formatter.date(from: "2025-10-20 13:00:00")?.ISO8601Format() ?? ""
        let start2 = formatter.date(from: "2025-10-20 15:00:00")?.ISO8601Format() ?? ""
        let end2 = formatter.date(from: "2025-10-20 15:30:00")?.ISO8601Format() ?? ""
        let body = """
            {
                "checkIn":      "\(checkIn)",
                "checkOut":     "\(checkOut)",
                "breakTimes": [{
                    "start":    "\(start1)",
                    "end":      "\(end1)"
                }, {
                    "start":    "\(start2)",
                    "end":      "\(end2)"
                }]
            }
            """
        try await runTest(method: .POST, uri: uri, body: body)
        #expect(responseHead?.status == .unauthorized)
        #expect(responseHead?.headers.first(name: "WWW-Authenticate") == "Bearer")
    }
    
    @Test mutating func testPatchRecord() async throws {
        let uri = "/timecard/records/\(records[1].id.uuidString)"
        let checkIn = formatter.date(from: "2025-10-18 08:00:00")?.ISO8601Format() ?? ""
        let checkOut = formatter.date(from: "2025-10-18 19:30:00")?.ISO8601Format() ?? ""
        let start = formatter.date(from: "2025-10-18 15:00:00")?.ISO8601Format() ?? ""
        let end = formatter.date(from: "2025-10-18 15:30:00")?.ISO8601Format() ?? ""
        let body = """
            {
                "checkIn":      "\(checkIn)",
                "checkOut":     "\(checkOut)",
                "breakTimes": [{
                    "start":    "\(start)",
                    "end":      "\(end)"
                }]
            }
            """
        try await runTest(method: .PATCH, uri: uri, token: publishToken(), body: body)
        #expect(responseHead?.status == .ok)
        #expect(responseHead?.headers.first(name: "Content-Type") == "application/json")
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.year == 2025 && $0.month == 10 },
            sortBy: [.init(\.checkIn)]
        )
        let records = try context.fetch(descriptor)
        #expect(records[0].checkIn?.day == 15)
        #expect(records[0].checkOut?.day == 15)
        #expect(records[1].checkIn?.ISO8601Format() == checkIn)
        #expect(records[1].checkOut?.ISO8601Format() == checkOut)
        #expect(records[1].breakTimes.count == 1)
        #expect(records[1].breakTimes[0].start?.ISO8601Format() == start)
        #expect(records[1].breakTimes[0].end?.ISO8601Format() == end)
        
        let responseBody = self.responseBody as? [[String: Any]]
        #expect(responseBody?.count == 1)
        
        let dict = responseBody?[0]
        let record = records[1]
        #expect(dict?["id"] as? String == record.id.uuidString)
        #expect(dict?["checkIn"] as? String == record.checkIn?.ISO8601Format())
        #expect(dict?["checkOut"] as? String == record.checkOut?.ISO8601Format())
        
        let breakTimes = dict?["breakTimes"] as? [[String: Any]]
        #expect(breakTimes?.count == record.breakTimes.count)
        for i in 0..<record.breakTimes.count {
            let dict = breakTimes?[i]
            let breakTime = record.breakTimes[i]
            #expect(dict?["id"] as? String == breakTime.id.uuidString)
            #expect(dict?["start"] as? String == breakTime.start?.ISO8601Format())
            #expect(dict?["end"] as? String == breakTime.end?.ISO8601Format())
        }
    }
    
    @Test mutating func testPatchRecord_wrongBody() async throws {
        let uri = "/timecard/records/\(records[1].id.uuidString)"
        let checkIn = formatter.date(from: "2025-10-18 08:00:00")?.ISO8601Format() ?? ""
        let checkOut = formatter.date(from: "2025-10-18 19:30:00")?.ISO8601Format() ?? ""
        let body = """
            {
                "checkIn":  "\(checkIn)",
                "checkOut": "\(checkOut)",
                "wrongKey": "wrongValue"
            }
            """
        try await runTest(method: .PATCH, uri: uri, token: publishToken(), body: body)
        #expect(responseHead?.status == .badRequest)
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.year == 2025 && $0.month == 10 },
            sortBy: [.init(\.checkIn)]
        )
        let records = try context.fetch(descriptor)
        #expect(records[1].checkIn?.hour == 10)
        #expect(records[1].checkOut?.hour == 18)
    }
    
    @Test mutating func testPatchRecord_missingParameter() async throws {
        let uri = "/timecard/records/\(records[1].id.uuidString)"
        let checkIn = formatter.date(from: "2025-10-18 08:00:00")?.ISO8601Format() ?? ""
        let checkOut = formatter.date(from: "2025-10-18 19:30:00")?.ISO8601Format() ?? ""
        let start = formatter.date(from: "2025-10-18 15:00:00")?.ISO8601Format() ?? ""
        let body = """
            {
                "checkIn":      "\(checkIn)",
                "checkOut":     "\(checkOut)",
                "breakTimes": [{
                    "start":    "\(start)"
                }]
            }
            """
        try await runTest(method: .PATCH, uri: uri, token: publishToken(), body: body)
        #expect(responseHead?.status == .badRequest)
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.year == 2025 && $0.month == 10 },
            sortBy: [.init(\.checkIn)]
        )
        let records = try context.fetch(descriptor)
        #expect(records[1].checkIn?.hour == 10)
        #expect(records[1].checkOut?.hour == 18)
    }
    
    @Test mutating func testPatchRecord_wrongId() async throws {
        let uri = "/timecard/records/\(UUID().uuidString)"
        let checkIn = formatter.date(from: "2025-10-18 08:00:00")?.ISO8601Format() ?? ""
        let checkOut = formatter.date(from: "2025-10-18 19:30:00")?.ISO8601Format() ?? ""
        let start = formatter.date(from: "2025-10-18 15:00:00")?.ISO8601Format() ?? ""
        let end = formatter.date(from: "2025-10-18 15:30:00")?.ISO8601Format() ?? ""
        let body = """
            {
                "checkIn":      "\(checkIn)",
                "checkOut":     "\(checkOut)",
                "breakTimes": [{
                    "start":    "\(start)",
                    "end":      "\(end)"
                }]
            }
            """
        try await runTest(method: .PATCH, uri: uri, token: publishToken(), body: body)
        #expect(responseHead?.status == .notFound)
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.year == 2025 && $0.month == 10 },
            sortBy: [.init(\.checkIn)]
        )
        let records = try context.fetch(descriptor)
        #expect(records[0].checkIn?.day == 15)
        #expect(records[0].checkOut?.day == 15)
        #expect(records[1].checkIn?.hour == 10)
        #expect(records[1].checkOut?.hour == 18)
    }
    
    @Test mutating func testPatchRecord_missingId() async throws {
        let uri = "/timecard/records/"
        let checkIn = formatter.date(from: "2025-10-18 08:00:00")?.ISO8601Format() ?? ""
        let checkOut = formatter.date(from: "2025-10-18 19:30:00")?.ISO8601Format() ?? ""
        let start = formatter.date(from: "2025-10-18 15:00:00")?.ISO8601Format() ?? ""
        let end = formatter.date(from: "2025-10-18 15:30:00")?.ISO8601Format() ?? ""
        let body = """
            {
                "checkIn":      "\(checkIn)",
                "checkOut":     "\(checkOut)",
                "breakTimes": [{
                    "start":    "\(start)",
                    "end":      "\(end)"
                }]
            }
            """
        try await runTest(method: .PATCH, uri: uri, token: publishToken(), body: body)
        #expect(responseHead?.status == .methodNotAllowed)
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.year == 2025 && $0.month == 10 },
            sortBy: [.init(\.checkIn)]
        )
        let records = try context.fetch(descriptor)
        #expect(records[0].checkIn?.day == 15)
        #expect(records[0].checkOut?.day == 15)
        #expect(records[1].checkIn?.hour == 10)
        #expect(records[1].checkOut?.hour == 18)
    }
    
    @Test mutating func testPatchRecord_unauthorized() async throws {
        let uri = "/timecard/records/\(records[1].id.uuidString)"
        let checkIn = formatter.date(from: "2025-10-18 08:00:00")?.ISO8601Format() ?? ""
        let checkOut = formatter.date(from: "2025-10-18 19:30:00")?.ISO8601Format() ?? ""
        let start = formatter.date(from: "2025-10-18 15:00:00")?.ISO8601Format() ?? ""
        let end = formatter.date(from: "2025-10-18 15:30:00")?.ISO8601Format() ?? ""
        let body = """
            {
                "checkIn":      "\(checkIn)",
                "checkOut":     "\(checkOut)",
                "breakTimes": [{
                    "start":    "\(start)",
                    "end":      "\(end)"
                }]
            }
            """
        try await runTest(method: .PATCH, uri: uri, body: body)
        #expect(responseHead?.status == .unauthorized)
        #expect(responseHead?.headers.first(name: "WWW-Authenticate") == "Bearer")
    }
    
    @Test mutating func testDeleteRecord() async throws {
        let uri = "/timecard/records/\(records[1].id.uuidString)"
        try await runTest(method: .DELETE, uri: uri, token: publishToken())
        #expect(responseHead?.status == .ok)
        #expect(responseHead?.headers.first(name: "Content-Type") == "application/json")
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.year == 2025 && $0.month == 10 },
            sortBy: [.init(\.checkIn)]
        )
        let records = try context.fetch(descriptor)
        #expect(records.count == 1)
        #expect(records[0].checkIn?.day == 15)
        
        let responseBody = self.responseBody as? [[String: Any]]
        #expect(responseBody?.count == 0)
    }
    
    @Test mutating func testDeleteRecord_wrongId() async throws {
        let uri = "/timecard/records/\(UUID().uuidString)"
        try await runTest(method: .DELETE, uri: uri, token: publishToken())
        #expect(responseHead?.status == .notFound)
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.year == 2025 && $0.month == 10 },
            sortBy: [.init(\.checkIn)]
        )
        let records = try context.fetch(descriptor)
        #expect(records.count == 2)
        #expect(records[0].checkIn?.day == 15)
        #expect(records[1].checkIn?.day == 18)
    }
    
    @Test mutating func testDeleteRecord_missingId() async throws {
        let uri = "/timecard/records/"
        try await runTest(method: .DELETE, uri: uri, token: publishToken())
        #expect(responseHead?.status == .methodNotAllowed)
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.year == 2025 && $0.month == 10 },
            sortBy: [.init(\.checkIn)]
        )
        let records = try context.fetch(descriptor)
        #expect(records.count == 2)
        #expect(records[0].checkIn?.day == 15)
        #expect(records[1].checkIn?.day == 18)
    }
    
    @Test mutating func testDeleteRecord_unauthorized() async throws {
        let uri = "/timecard/records/\(records[1].id.uuidString)"
        try await runTest(method: .DELETE, uri: uri)
        #expect(responseHead?.status == .unauthorized)
        #expect(responseHead?.headers.first(name: "WWW-Authenticate") == "Bearer")
    }
    
    @Test mutating func testGetBreakTime() async throws {
        let uri = "/timecard/breaktimes/\(records[1].breakTimes[0].id.uuidString)"
        try await runTest(method: .GET, uri: uri, token: publishToken())
        #expect(responseHead?.status == .ok)
        #expect(responseHead?.headers.first(name: "Content-Type") == "application/json")
        
        let responseBody = self.responseBody as? [[String: Any]]
        #expect(responseBody?.count == 1)
        
        let dict = responseBody?[0]
        let record = records[1].breakTimes[0]
        #expect(dict?["id"] as? String == record.id.uuidString)
        #expect(dict?["start"] as? String == record.start?.ISO8601Format())
        #expect(dict?["end"] as? String == record.end?.ISO8601Format())
    }
    
    @Test mutating func testGetBreakTime_wrongId() async throws {
        let uri = "/timecard/breaktimes/\(UUID().uuidString)"
        try await runTest(method: .GET, uri: uri, token: publishToken())
        #expect(responseHead?.status == .notFound)
    }
    
    @Test mutating func testGetBreakTime_missingId() async throws {
        let uri = "/timecard/breaktimes"
        try await runTest(method: .GET, uri: uri, token: publishToken())
        #expect(responseHead?.status == .notFound)
    }
    
    @Test mutating func testGetBreakTime_tooManyPath() async throws {
        let uri = "/timecard/breaktimes/\(records[1].breakTimes[0].id.uuidString)/redundant"
        try await runTest(method: .GET, uri: uri, token: publishToken())
        #expect(responseHead?.status == .notFound)
    }
    
    @Test mutating func testGetBreakTime_unauthorized() async throws {
        let uri = "/timecard/breaktimes/\(records[1].breakTimes[0].id.uuidString)"
        try await runTest(method: .GET, uri: uri)
        #expect(responseHead?.status == .unauthorized)
        #expect(responseHead?.headers.first(name: "WWW-Authenticate") == "Bearer")
    }
    
    @Test mutating func testRegisterUser() async throws {
        let uri = "/timecard/auth/register"
        let mail = "mail@test.com"
        let password = "Password"
        let body = """
            {
                "mail":     "\(mail)",
                "password": "\(password)"
            }
            """
        try await runTest(method: .POST, uri: uri, body: body)
        #expect(responseHead?.status == .created)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let users = try context.fetch(descriptor)
        #expect(users.count == 1)
        #expect(users[0].mail == mail)
        #expect(users[0].password == password)
        
        #expect(verifyCodeSender.recipient == mail)
    }
    
    @Test mutating func testRegisterUser_wrongBody() async throws {
        let uri = "/timecard/auth/register"
        let mail = "mail@test.com"
        let body = """
            {
                "mail":     "\(mail)"
            }
            """
        try await runTest(method: .POST, uri: uri, body: body)
        #expect(responseHead?.status == .badRequest)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let users = try context.fetch(descriptor)
        #expect(users.count == 0)
        
        #expect(verifyCodeSender.recipient == "")
    }
    
    @Test mutating func testRegisterUser_duplicate() async throws {
        let mail = "mail@test.com"
        let password1 = "111"
        let user = User(mail: mail, password: password1)
        context.insert(user.asLocal())
        try context.save()
        
        let uri = "/timecard/auth/register"
        let password2 = "222"
        let body = """
            {
                "mail":     "\(mail)",
                "password": "\(password2)"
            }
            """
        try await runTest(method: .POST, uri: uri, body: body)
        #expect(responseHead?.status == .unprocessableEntity)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let users = try context.fetch(descriptor)
        #expect(users.count == 1)
        #expect(users[0].mail == mail)
        #expect(users[0].password == password1)
        
        #expect(verifyCodeSender.recipient == "")
    }
    
    @Test mutating func testVerifyUser() async throws {
        let mail = "mail@test.com"
        let verifyCode = "123456"
        let user = User(
            mail: mail,
            password: "pass",
            verifyCode: try HMACSHA256.computeHash(verifyCode).base64EncodedString(),
            verifyCodeExpires: Date(timeIntervalSinceNow: 100)
        )
        context.insert(user.asLocal())
        try context.save()
        
        let uri = "/timecard/auth/verify"
        let body = """
            {
                "mail":         "\(mail)",
                "verifyCode":   "\(verifyCode)"
            }
            """
        try await runTest(method: .POST, uri: uri, body: body)
        #expect(responseHead?.status == .ok)
        
        let responseBody = self.responseBody as? [String: Any]
        let accessToken = responseBody?["accessToken"] as? String ?? ""
        let refreshToken = responseBody?["refreshToken"] as? String ?? ""
        
        let descriptor = FetchDescriptor<LocalUser>()
        let users = try context.fetch(descriptor).map { $0.asUser() }
        #expect(users.count == 1)
        #expect(users[0].mail == mail)
        #expect(users[0].verified == true)
        #expect(users[0].refreshTokens.count == 1)
        #expect(users[0].refreshTokens[0].token == (try HMACSHA256.computeHash(refreshToken).base64EncodedString()))
        #expect(users[0].refreshTokens[0].status == .valid)
        
        #expect(userRepository.verifyLogin(token: accessToken) == true)
        #expect(throws: Never.self) {
            try userRepository.refresh(token: refreshToken)
        }
    }
    
    @Test mutating func testVerifyUser_wrongBody() async throws {
        let mail = "mail@test.com"
        let verifyCode = "123456"
        let user = User(
            mail: mail,
            password: "pass",
            verifyCode: try HMACSHA256.computeHash(verifyCode).base64EncodedString(),
            verifyCodeExpires: Date(timeIntervalSinceNow: 100)
        )
        context.insert(user.asLocal())
        try context.save()
        
        let uri = "/timecard/auth/verify"
        let body = """
            {
                "mail":         "\(mail)"
            }
            """
        try await runTest(method: .POST, uri: uri, body: body)
        #expect(responseHead?.status == .badRequest)
        
        let responseBody = self.responseBody as? [String: Any]
        #expect(responseBody?["accessToken"] == nil)
        #expect(responseBody?["refreshToken"] == nil)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let users = try context.fetch(descriptor).map { $0.asUser() }
        #expect(users.count == 1)
        #expect(users[0].mail == mail)
        #expect(users[0].verified == false)
    }
    
    @Test mutating func testVerifyUser_wrongCode() async throws {
        let mail = "mail@test.com"
        let verifyCode = "123456"
        let user = User(
            mail: mail,
            password: "pass",
            verifyCode: try HMACSHA256.computeHash(verifyCode).base64EncodedString(),
            verifyCodeExpires: Date(timeIntervalSinceNow: 100)
        )
        context.insert(user.asLocal())
        try context.save()
        
        let uri = "/timecard/auth/verify"
        let body = """
            {
                "mail":         "\(mail)",
                "verifyCode":   "000000"
            }
            """
        try await runTest(method: .POST, uri: uri, body: body)
        #expect(responseHead?.status == .unprocessableEntity)
        
        let responseBody = self.responseBody as? [String: Any]
        #expect(responseBody?["accessToken"] == nil)
        #expect(responseBody?["refreshToken"] == nil)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let users = try context.fetch(descriptor).map { $0.asUser() }
        #expect(users.count == 1)
        #expect(users[0].mail == mail)
        #expect(users[0].verified == false)
    }
    
    @Test mutating func testVerifyUser_expiredCode() async throws {
        let mail = "mail@test.com"
        let verifyCode = "123456"
        let user = User(
            mail: mail,
            password: "pass",
            verifyCode: try HMACSHA256.computeHash(verifyCode).base64EncodedString(),
            verifyCodeExpires: Date(timeIntervalSinceNow: -100)
        )
        context.insert(user.asLocal())
        try context.save()
        
        let uri = "/timecard/auth/verify"
        let body = """
            {
                "mail":         "\(mail)",
                "verifyCode":   "\(verifyCode)"
            }
            """
        try await runTest(method: .POST, uri: uri, body: body)
        #expect(responseHead?.status == .unprocessableEntity)
        
        let responseBody = self.responseBody as? [String: Any]
        #expect(responseBody?["accessToken"] == nil)
        #expect(responseBody?["refreshToken"] == nil)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let users = try context.fetch(descriptor).map { $0.asUser() }
        #expect(users.count == 1)
        #expect(users[0].mail == mail)
        #expect(users[0].verified == false)
    }
    
    @Test mutating func testVerifyUser_exceedAttempts() async throws {
        let mail = "mail@test.com"
        let verifyCode = "123456"
        let user = User(
            mail: mail,
            password: "pass",
            verifyCode: try HMACSHA256.computeHash(verifyCode).base64EncodedString(),
            verifyCodeExpires: Date(timeIntervalSinceNow: 100),
            verifyAttempts: 10
        )
        context.insert(user.asLocal())
        try context.save()
        
        let uri = "/timecard/auth/verify"
        let body = """
            {
                "mail":         "\(mail)",
                "verifyCode":   "\(verifyCode)"
            }
            """
        try await runTest(method: .POST, uri: uri, body: body)
        #expect(responseHead?.status == .tooManyRequests)
        
        let responseBody = self.responseBody as? [String: Any]
        #expect(responseBody?["accessToken"] == nil)
        #expect(responseBody?["refreshToken"] == nil)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let users = try context.fetch(descriptor).map { $0.asUser() }
        #expect(users.count == 1)
        #expect(users[0].mail == mail)
        #expect(users[0].verified == false)
    }
    
    @Test mutating func testLogin() async throws {
        let mail = "mail@test.com"
        let password = "Password"
        let user = User(
            mail: mail,
            password: password
        )
        context.insert(user.asLocal())
        try context.save()
        
        let uri = "/timecard/auth/login"
        let body = """
            {
                "mail":     "\(mail)",
                "password": "\(password)"
            }
            """
        try await runTest(method: .POST, uri: uri, body: body)
        #expect(responseHead?.status == .ok)
        
        let responseBody = self.responseBody as? [String: Any]
        let accessToken = responseBody?["accessToken"] as? String ?? ""
        let refreshToken = responseBody?["refreshToken"] as? String ?? ""
        
        let descriptor = FetchDescriptor<LocalUser>()
        let users = try context.fetch(descriptor).map { $0.asUser() }
        #expect(users.count == 1)
        #expect(users[0].mail == mail)
        #expect(users[0].locked == nil)
        #expect(users[0].refreshTokens.count == 1)
        #expect(users[0].refreshTokens[0].token == (try HMACSHA256.computeHash(refreshToken).base64EncodedString()))
        #expect(users[0].refreshTokens[0].status == .valid)
        
        #expect(userRepository.verifyLogin(token: accessToken) == true)
        #expect(throws: Never.self) {
            try userRepository.refresh(token: refreshToken)
        }
    }
    
    @Test mutating func testLogin_wrongBody() async throws {
        let mail = "mail@test.com"
        let password = "Password"
        let user = User(
            mail: mail,
            password: password
        )
        context.insert(user.asLocal())
        try context.save()
        
        let uri = "/timecard/auth/login"
        let body = """
            {
                "mail":     "\(mail)"
            }
            """
        try await runTest(method: .POST, uri: uri, body: body)
        #expect(responseHead?.status == .badRequest)
        
        let responseBody = self.responseBody as? [String: Any]
        #expect(responseBody?["accessToken"] == nil)
        #expect(responseBody?["refreshToken"] == nil)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let users = try context.fetch(descriptor).map { $0.asUser() }
        #expect(users.count == 1)
        #expect(users[0].mail == mail)
        #expect(users[0].loginAttempts == 0)
    }
    
    @Test mutating func testLogin_wrongPassword() async throws {
        let mail = "mail@test.com"
        let password = "Password"
        let user = User(
            mail: mail,
            password: password
        )
        context.insert(user.asLocal())
        try context.save()
        
        let uri = "/timecard/auth/login"
        let body = """
            {
                "mail":     "\(mail)",
                "password": "test"
            }
            """
        try await runTest(method: .POST, uri: uri, body: body)
        #expect(responseHead?.status == .unauthorized)
        
        let responseBody = self.responseBody as? [String: Any]
        #expect(responseBody?["accessToken"] == nil)
        #expect(responseBody?["refreshToken"] == nil)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let users = try context.fetch(descriptor).map { $0.asUser() }
        #expect(users.count == 1)
        #expect(users[0].mail == mail)
        #expect(users[0].loginAttempts == 1)
    }
    
    @Test mutating func testLogin_locked() async throws {
        let mail = "mail@test.com"
        let password = "Password"
        let locked = Date.now
        let user = User(
            mail: mail,
            password: password,
            locked: locked
        )
        context.insert(user.asLocal())
        try context.save()
        
        let uri = "/timecard/auth/login"
        let body = """
            {
                "mail":     "\(mail)",
                "password": "\(password)"
            }
            """
        try await runTest(method: .POST, uri: uri, body: body)
        #expect(responseHead?.status == .unauthorized)
        
        let responseBody = self.responseBody as? [String: Any]
        #expect(responseBody?["accessToken"] == nil)
        #expect(responseBody?["refreshToken"] == nil)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let users = try context.fetch(descriptor).map { $0.asUser() }
        #expect(users.count == 1)
        #expect(users[0].mail == mail)
        #expect(users[0].loginAttempts == 0)
        #expect(users[0].locked == locked)
    }
    
    @Test mutating func testRefreshToken() async throws {
        let mail = "mail@test.com"
        let password = "Password"
        let token = "refresh"
        let user = User(
            mail: mail,
            password: password,
            refreshTokens: [
                User.RefreshToken(
                    token: try HMACSHA256.computeHash(token).base64EncodedString(),
                    status: .valid,
                    expire: Date(timeIntervalSinceNow: 100)
                )
            ]
        )
        context.insert(user.asLocal())
        try context.save()
        
        let uri = "/timecard/auth/refresh"
        let body = """
            {
                "refreshToken": "\(token)"
            }
            """
        try await runTest(method: .POST, uri: uri, body: body)
        #expect(responseHead?.status == .ok)
        
        let responseBody = self.responseBody as? [String: Any]
        let accessToken = responseBody?["accessToken"] as? String ?? ""
        let refreshToken = responseBody?["refreshToken"] as? String ?? ""
        
        let descriptor = FetchDescriptor<LocalUser>()
        let users = try context.fetch(descriptor).map { $0.asUser() }
        #expect(users.count == 1)
        #expect(users[0].mail == mail)
        #expect(users[0].refreshTokens.count == 2)
        
        let used = try users[0].refreshTokens.first { $0.token == (try HMACSHA256.computeHash(token).base64EncodedString()) }
        #expect(used != nil)
        #expect(used?.status == .used)
        
        let refreshed = try users[0].refreshTokens.first { $0.token == (try HMACSHA256.computeHash(refreshToken).base64EncodedString()) }
        #expect(refreshed != nil)
        #expect(refreshed?.status == .valid)
        
        #expect(userRepository.verifyLogin(token: accessToken) == true)
        #expect(throws: Never.self) {
            try userRepository.refresh(token: refreshToken)
        }
    }
    
    @Test mutating func testRefreshToken_wrongBody() async throws {
        let mail = "mail@test.com"
        let password = "Password"
        let token = "refresh"
        let user = User(
            mail: mail,
            password: password,
            refreshTokens: [
                User.RefreshToken(
                    token: try HMACSHA256.computeHash(token).base64EncodedString(),
                    status: .valid,
                    expire: Date(timeIntervalSinceNow: 100)
                )
            ]
        )
        context.insert(user.asLocal())
        try context.save()
        
        let uri = "/timecard/auth/refresh"
        let body = """
            {
                "mail": "mail@test.com"
            }
            """
        try await runTest(method: .POST, uri: uri, body: body)
        #expect(responseHead?.status == .badRequest)
        
        let responseBody = self.responseBody as? [String: Any]
        #expect(responseBody?["accessToken"] == nil)
        #expect(responseBody?["refreshToken"] == nil)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let users = try context.fetch(descriptor).map { $0.asUser() }
        #expect(users.count == 1)
        #expect(users[0].mail == mail)
        #expect(users[0].refreshTokens.count == 1)
        #expect(users[0].refreshTokens[0].token == (try HMACSHA256.computeHash(token).base64EncodedString()))
        #expect(users[0].refreshTokens[0].status == .valid)
    }
    
    @Test mutating func testRefreshToken_wrongToken() async throws {
        let mail = "mail@test.com"
        let password = "Password"
        let token = "refresh"
        let user = User(
            mail: mail,
            password: password,
            refreshTokens: [
                User.RefreshToken(
                    token: try HMACSHA256.computeHash(token).base64EncodedString(),
                    status: .valid,
                    expire: Date(timeIntervalSinceNow: 100)
                )
            ]
        )
        context.insert(user.asLocal())
        try context.save()
        
        let uri = "/timecard/auth/refresh"
        let body = """
            {
                "refreshToken": "aaa"
            }
            """
        try await runTest(method: .POST, uri: uri, body: body)
        #expect(responseHead?.status == .unauthorized)
        
        let responseBody = self.responseBody as? [String: Any]
        #expect(responseBody?["accessToken"] == nil)
        #expect(responseBody?["refreshToken"] == nil)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let users = try context.fetch(descriptor).map { $0.asUser() }
        #expect(users.count == 1)
        #expect(users[0].mail == mail)
        #expect(users[0].refreshTokens.count == 1)
        #expect(users[0].refreshTokens[0].token == (try HMACSHA256.computeHash(token).base64EncodedString()))
        #expect(users[0].refreshTokens[0].status == .valid)
    }
    
    @Test mutating func testRefreshToken_expiredToken() async throws {
        let mail = "mail@test.com"
        let password = "Password"
        let token = "refresh"
        let user = User(
            mail: mail,
            password: password,
            refreshTokens: [
                User.RefreshToken(
                    token: try HMACSHA256.computeHash(token).base64EncodedString(),
                    status: .valid,
                    expire: Date(timeIntervalSinceNow: -100)
                )
            ]
        )
        context.insert(user.asLocal())
        try context.save()
        
        let uri = "/timecard/auth/refresh"
        let body = """
            {
                "refreshToken": "\(token)"
            }
            """
        try await runTest(method: .POST, uri: uri, body: body)
        #expect(responseHead?.status == .unauthorized)
        
        let responseBody = self.responseBody as? [String: Any]
        #expect(responseBody?["accessToken"] == nil)
        #expect(responseBody?["refreshToken"] == nil)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let users = try context.fetch(descriptor).map { $0.asUser() }
        #expect(users.count == 1)
        #expect(users[0].mail == mail)
        #expect(users[0].refreshTokens.count == 1)
        #expect(users[0].refreshTokens[0].token == (try HMACSHA256.computeHash(token).base64EncodedString()))
        #expect(users[0].refreshTokens[0].status == .valid)
    }
    
    @Test mutating func testRefreshToken_usedToken() async throws {
        let mail = "mail@test.com"
        let password = "Password"
        let token = "refresh"
        let user = User(
            mail: mail,
            password: password,
            refreshTokens: [
                User.RefreshToken(
                    token: try HMACSHA256.computeHash(token).base64EncodedString(),
                    status: .used,
                    expire: Date(timeIntervalSinceNow: 100)
                ),
                User.RefreshToken(
                    token: "token2",
                    status: .valid,
                    expire: Date(timeIntervalSinceNow: 100)
                )
            ]
        )
        context.insert(user.asLocal())
        try context.save()
        
        let uri = "/timecard/auth/refresh"
        let body = """
            {
                "refreshToken": "\(token)"
            }
            """
        try await runTest(method: .POST, uri: uri, body: body)
        #expect(responseHead?.status == .unauthorized)
        
        let responseBody = self.responseBody as? [String: Any]
        #expect(responseBody?["accessToken"] == nil)
        #expect(responseBody?["refreshToken"] == nil)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let users = try context.fetch(descriptor).map { $0.asUser() }
        #expect(users.count == 1)
        #expect(users[0].mail == mail)
        #expect(users[0].refreshTokens.count == 2)
        #expect(users[0].refreshTokens[0].status == .revoked)
        #expect(users[0].refreshTokens[1].status == .revoked)
    }
    
    private class FakeVerifyCodeSender: VerifyCodeSender {
        var recipient: String = ""
        var verifyCode: String = ""
        var expire: Date? = nil
        func send(to recipient: String, verifyCode: String, expire: Date) async throws {
            self.recipient = recipient
            self.verifyCode = verifyCode
            self.expire = expire
        }
    }
    
    private class FakePasswordHasher: PasswordHasher {
        func hash(_ password: String) async throws -> String {
            password
        }
        
        func verify(password: String, hash: String) async throws -> Bool {
            password == hash
        }
    }
}
