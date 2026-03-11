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

    var records: [TimeRecord] = []
    var container: ModelContainer!
    var context: ModelContext!
    var formatter: DateFormatter
    var channel: EmbeddedChannel!
    var responseHead: HTTPResponseHead? = nil
    var responseBody: [[String: Any]]? = nil
    var responseEnd: HTTPHeaders? = nil
    
    init() async throws {
        formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        try setupContext()
        try await setupChannel()
    }
    
    private mutating func setupContext() throws {
        let schema = Schema([LocalTimeRecord.self])
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
    
    private mutating func setupChannel() async throws {
        let source = DefaultLocalDataSource(context)
        let repository = DefaultTimeRecordRepository(source)
        let handler = TimeCardServer.TimeCardServerHandler(repository)
        channel = EmbeddedChannel()
        try await channel.pipeline.addHandler(handler)
    }
    
    private mutating func runTest(method: HTTPMethod, uri: String, body: String) throws {
        let head = HTTPRequestHead(version: .init(major: 1, minor: 1), method: method, uri: uri)
        let body = channel.allocator.buffer(string: body)
        let requestHead = HTTPServerRequestPart.head(head)
        let requestBody = HTTPServerRequestPart.body(body)
        let requestEnd = HTTPServerRequestPart.end(nil)
        try channel.writeInbound(requestHead)
        try channel.writeInbound(requestBody)
        try channel.writeInbound(requestEnd)
        
        let responseHead: HTTPServerResponsePart? = try channel.readOutbound()
        let responseBody: HTTPServerResponsePart? = try channel.readOutbound()
        let responseEnd: HTTPServerResponsePart? = try channel.readOutbound()
        if case .head(let head) = responseHead {
            self.responseHead = head
        }
        
        if case .body(.byteBuffer(let body)) = responseBody {
            self.responseBody = try? JSONSerialization.jsonObject(with: body) as? [[String: Any]]
        }
        
        if case .end(let end) = responseEnd {
            self.responseEnd = end
        }
    }
    
    @Test mutating func testGetRecords() async throws {
        try runTest(method: .GET, uri: "/timecard/records?year=2025&month=10", body: "")
        #expect(responseHead?.status == .ok)
        #expect(responseHead?.headers.first(name: "Content-Type") == "application/json")
        
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
        try runTest(method: .GET, uri: "/timecard/records", body: "")
        #expect(responseHead?.status == .badRequest)
    }
    
    @Test mutating func testGetRecords_wrongMethod() async throws {
        try runTest(method: .ACL, uri: "/timecard/records?year=2025&month=10", body: "")
        #expect(responseHead?.status == .methodNotAllowed)
    }
    
    @Test mutating func testGetRecord() async throws {
        let uri = "/timecard/records/\(records[1].id.uuidString)"
        try runTest(method: .GET, uri: uri, body: "")
        #expect(responseHead?.status == .ok)
        #expect(responseHead?.headers.first(name: "Content-Type") == "application/json")
        
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
        try runTest(method: .GET, uri: uri, body: "")
        #expect(responseHead?.status == .notFound)
    }
    
    @Test mutating func testGetRecord_tooManyPath() async throws {
        let uri = "/timecard/records/\(records[1].id.uuidString)/redundant"
        try runTest(method: .GET, uri: uri, body: "")
        #expect(responseHead?.status == .notFound)
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
        try runTest(method: .POST, uri: uri, body: body)
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
        try runTest(method: .POST, uri: uri, body: body)
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
        try runTest(method: .POST, uri: uri, body: body)
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
        try runTest(method: .POST, uri: uri, body: body)
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
        try runTest(method: .PATCH, uri: uri, body: body)
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
        try runTest(method: .PATCH, uri: uri, body: body)
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
        try runTest(method: .PATCH, uri: uri, body: body)
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
        try runTest(method: .PATCH, uri: uri, body: body)
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
        try runTest(method: .PATCH, uri: uri, body: body)
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
    
    @Test mutating func testDeleteRecord() async throws {
        let uri = "/timecard/records/\(records[1].id.uuidString)"
        try runTest(method: .DELETE, uri: uri, body: "")
        #expect(responseHead?.status == .ok)
        #expect(responseHead?.headers.first(name: "Content-Type") == "application/json")
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.year == 2025 && $0.month == 10 },
            sortBy: [.init(\.checkIn)]
        )
        let records = try context.fetch(descriptor)
        #expect(records.count == 1)
        #expect(records[0].checkIn?.day == 15)
        
        #expect(responseBody?.count == 0)
    }
    
    @Test mutating func testDeleteRecord_wrongId() async throws {
        let uri = "/timecard/records/\(UUID().uuidString)"
        try runTest(method: .DELETE, uri: uri, body: "")
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
        try runTest(method: .DELETE, uri: uri, body: "")
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
    
    @Test mutating func testGetBreakTime() async throws {
        let uri = "/timecard/breaktimes/\(records[1].breakTimes[0].id.uuidString)"
        try runTest(method: .GET, uri: uri, body: "")
        #expect(responseHead?.status == .ok)
        #expect(responseHead?.headers.first(name: "Content-Type") == "application/json")
        
        #expect(responseBody?.count == 1)
        
        let dict = responseBody?[0]
        let record = records[1].breakTimes[0]
        #expect(dict?["id"] as? String == record.id.uuidString)
        #expect(dict?["start"] as? String == record.start?.ISO8601Format())
        #expect(dict?["end"] as? String == record.end?.ISO8601Format())
    }
    
    @Test mutating func testGetBreakTime_wrongId() async throws {
        let uri = "/timecard/breaktimes/\(UUID().uuidString)"
        try runTest(method: .GET, uri: uri, body: "")
        #expect(responseHead?.status == .notFound)
    }
    
    @Test mutating func testGetBreakTime_missingId() async throws {
        let uri = "/timecard/breaktimes"
        try runTest(method: .GET, uri: uri, body: "")
        #expect(responseHead?.status == .notFound)
    }
    
    @Test mutating func testGetBreakTime_tooManyPath() async throws {
        let uri = "/timecard/breaktimes/\(records[1].breakTimes[0].id.uuidString)/redundant"
        try runTest(method: .GET, uri: uri, body: "")
        #expect(responseHead?.status == .notFound)
    }
}
