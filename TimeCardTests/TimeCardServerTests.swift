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
    var channel: EmbeddedChannel!
    var responseHead: HTTPResponseHead? = nil
    var responseBody: [[String: Any]]? = nil
    var responseEnd: HTTPHeaders? = nil
    
    init() async throws {
        try setupContext()
        try await setupChannel()
    }
    
    private mutating func setupContext() throws {
        let schema = Schema([TimeRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
        
        var record = TimeRecord(year: 2025, month: 10, checkIn: date(2025, 10, 15, 9, 30, 0), checkOut: date(2025, 10, 15, 17, 0, 0))
        records.append(record)
        var breakTime = TimeRecord.BreakTime(start: date(2025, 10, 15, 12, 15, 0), end: date(2025, 10, 15, 12, 45, 0))
        record.breakTimes.append(breakTime)
        context.insert(record)
        
        record = TimeRecord(year: 2025, month: 10, checkIn: date(2025, 10, 18, 10, 0, 0), checkOut: date(2025, 10, 18, 18, 30, 0))
        records.append(record)
        breakTime = TimeRecord.BreakTime(start: date(2025, 10, 18, 12, 30, 0), end: date(2025, 10, 15, 13, 0, 0))
        record.breakTimes.append(breakTime)
        breakTime = TimeRecord.BreakTime(start: date(2025, 10, 18, 17, 30, 0), end: date(2025, 10, 15, 18, 0, 0))
        record.breakTimes.append(breakTime)
        context.insert(record)
    }
    
    private mutating func setupChannel() async throws {
        let handler = TimeCardServer.TimeCardServerHandler(context: context)
        channel = EmbeddedChannel()
        try await channel.pipeline.addHandler(handler)
    }
    
    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int) -> Date? {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second))
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
        try runTest(method: .GET, uri: "timecard/records?year=2025&month=10", body: "")
        #expect(responseHead?.status == .ok)
        #expect(responseHead?.headers.first(name: "Content-Type") == "application/json")
        
        #expect(responseBody?.count == records.count)
        for i in 0..<records.count {
            let dict = responseBody?[i]
            let record = records[i]
            #expect(dict?["id"] as? String == record.id.uuidString)
            #expect(dict?["checkIn"] as? Double == record.checkIn?.timeIntervalSinceReferenceDate)
            #expect(dict?["checkOut"] as? Double == record.checkOut?.timeIntervalSinceReferenceDate)
            
            let breakTimes = dict?["breakTimes"] as? [[String: Any]]
            #expect(breakTimes?.count == record.breakTimes.count)
            for i in 0..<record.breakTimes.count {
                let dict = breakTimes?[i]
                let breakTime = record.breakTimes[i]
                #expect(dict?["id"] as? String == breakTime.id.uuidString)
                #expect(dict?["start"] as? Double == breakTime.start?.timeIntervalSinceReferenceDate)
                #expect(dict?["end"] as? Double == breakTime.end?.timeIntervalSinceReferenceDate)
            }
        }
    }

    @Test mutating func testGetRecords_missingParameter() async throws {
        try runTest(method: .GET, uri: "timecard/records", body: "")
        #expect(responseHead?.status == .badRequest)
    }
    
    @Test mutating func testGetRecords_wrongMethod() async throws {
        try runTest(method: .POST, uri: "timecard/records?year=2025&month=10", body: "")
        #expect(responseHead?.status == .badRequest)
    }
    
    @Test mutating func testGetRecord() async throws {
        let uri = "timecard/records/\(records[1].id.uuidString)"
        try runTest(method: .GET, uri: uri, body: "")
        #expect(responseHead?.status == .ok)
        #expect(responseHead?.headers.first(name: "Content-Type") == "application/json")
        
        #expect(responseBody?.count == 1)
        
        let dict = responseBody?[0]
        let record = records[1]
        #expect(dict?["id"] as? String == record.id.uuidString)
        #expect(dict?["checkIn"] as? Double == record.checkIn?.timeIntervalSinceReferenceDate)
        #expect(dict?["checkOut"] as? Double == record.checkOut?.timeIntervalSinceReferenceDate)
        
        let breakTimes = dict?["breakTimes"] as? [[String: Any]]
        #expect(breakTimes?.count == record.breakTimes.count)
        for i in 0..<record.breakTimes.count {
            let dict = breakTimes?[i]
            let breakTime = record.breakTimes[i]
            #expect(dict?["id"] as? String == breakTime.id.uuidString)
            #expect(dict?["start"] as? Double == breakTime.start?.timeIntervalSinceReferenceDate)
            #expect(dict?["end"] as? Double == breakTime.end?.timeIntervalSinceReferenceDate)
        }
    }
    
    @Test mutating func testGetRecord_wrongId() async throws {
        let uri = "timecard/records/id"
        try runTest(method: .GET, uri: uri, body: "")
        #expect(responseHead?.status == .badRequest)
    }
    
    @Test mutating func testGetRecord_missingId() async throws {
        let uri = "timecard/records/"
        try runTest(method: .GET, uri: uri, body: "")
        #expect(responseHead?.status == .badRequest)
    }
    
    @Test mutating func testGetRecord_tooManyPath() async throws {
        let uri = "timecard/records/\(records[1].id.uuidString)/redundant"
        try runTest(method: .GET, uri: uri, body: "")
        #expect(responseHead?.status == .badRequest)
    }
    
    @Test mutating func testPutRecord() async throws {
        let uri = "timecard/records/\(records[1].id.uuidString)"
        let checkIn = date(2025, 10, 18, 8, 0, 0)?.timeIntervalSinceReferenceDate ?? 0
        let checkOut = date(2025, 10, 18, 19, 30, 0)?.timeIntervalSinceReferenceDate ?? 0
        let body = """
            {
                "checkIn":  \(checkIn),
                "checkOut": \(checkOut)
            }
            """
        try runTest(method: .PUT, uri: uri, body: body)
        #expect(responseHead?.status == .ok)
        #expect(responseHead?.headers.first(name: "Content-Type") == "application/json")
        
        #expect(records[0].checkIn?.day == 15)
        #expect(records[0].checkOut?.day == 15)
        #expect(records[1].checkIn?.timeIntervalSinceReferenceDate == checkIn)
        #expect(records[1].checkOut?.timeIntervalSinceReferenceDate == checkOut)
        
        #expect(responseBody?.count == 1)
        
        let dict = responseBody?[0]
        let record = records[1]
        #expect(dict?["id"] as? String == record.id.uuidString)
        #expect(dict?["checkIn"] as? Double == record.checkIn?.timeIntervalSinceReferenceDate)
        #expect(dict?["checkOut"] as? Double == record.checkOut?.timeIntervalSinceReferenceDate)
        
        let breakTimes = dict?["breakTimes"] as? [[String: Any]]
        #expect(breakTimes?.count == record.breakTimes.count)
        for i in 0..<record.breakTimes.count {
            let dict = breakTimes?[i]
            let breakTime = record.breakTimes[i]
            #expect(dict?["id"] as? String == breakTime.id.uuidString)
            #expect(dict?["start"] as? Double == breakTime.start?.timeIntervalSinceReferenceDate)
            #expect(dict?["end"] as? Double == breakTime.end?.timeIntervalSinceReferenceDate)
        }
    }
    
    @Test mutating func testPutRecord_wrongBody() async throws {
        let uri = "timecard/records/\(records[1].id.uuidString)"
        let checkIn = date(2025, 10, 18, 8, 0, 0)?.timeIntervalSinceReferenceDate ?? 0
        let checkOut = date(2025, 10, 18, 19, 30, 0)?.timeIntervalSinceReferenceDate ?? 0
        let body = """
            {
                "checkIn":  \(checkIn),
                "checkOut": \(checkOut),
                wrongKey:   wrongValue
            }
            """
        try runTest(method: .PUT, uri: uri, body: body)
        #expect(responseHead?.status == .badRequest)
        
        #expect(records[1].checkIn?.hour == 10)
        #expect(records[1].checkOut?.hour == 18)
    }
    
    @Test mutating func testPutRecord_missingParameter() async throws {
        let uri = "timecard/records/\(records[1].id.uuidString)"
        let checkIn = date(2025, 10, 18, 8, 0, 0)?.timeIntervalSinceReferenceDate ?? 0
        let body = """
            {
                "checkIn":  \(checkIn)
            }
            """
        try runTest(method: .PUT, uri: uri, body: body)
        #expect(responseHead?.status == .badRequest)
        
        #expect(records[1].checkIn?.hour == 10)
        #expect(records[1].checkOut?.hour == 18)
    }
    
    @Test mutating func testPutRecord_wrongId() async throws {
        let uri = "timecard/records/\(UUID().uuidString)"
        let checkIn = date(2025, 10, 18, 8, 0, 0)?.timeIntervalSinceReferenceDate ?? 0
        let checkOut = date(2025, 10, 18, 19, 30, 0)?.timeIntervalSinceReferenceDate ?? 0
        let body = """
            {
                "checkIn":  \(checkIn),
                "checkOut": \(checkOut)
            }
            """
        try runTest(method: .PUT, uri: uri, body: body)
        #expect(responseHead?.status == .notFound)
        
        #expect(records[0].checkIn?.day == 15)
        #expect(records[0].checkOut?.day == 15)
        #expect(records[1].checkIn?.hour == 10)
        #expect(records[1].checkOut?.hour == 18)
    }
    
    @Test mutating func testPutRecord_missingId() async throws {
        let uri = "timecard/records/"
        let checkIn = date(2025, 10, 18, 8, 0, 0)?.timeIntervalSinceReferenceDate ?? 0
        let checkOut = date(2025, 10, 18, 19, 30, 0)?.timeIntervalSinceReferenceDate ?? 0
        let body = """
            {
                "checkIn":  \(checkIn),
                "checkOut": \(checkOut)
            }
            """
        try runTest(method: .PUT, uri: uri, body: body)
        #expect(responseHead?.status == .badRequest)
        
        #expect(records[0].checkIn?.day == 15)
        #expect(records[0].checkOut?.day == 15)
        #expect(records[1].checkIn?.hour == 10)
        #expect(records[1].checkOut?.hour == 18)
    }
    
    @Test mutating func testGetBreakTime() async throws {
        let uri = "timecard/breaktime/\(records[1].breakTimes[0].id.uuidString)"
        try runTest(method: .GET, uri: uri, body: "")
        #expect(responseHead?.status == .ok)
        #expect(responseHead?.headers.first(name: "Content-Type") == "application/json")
        
        #expect(responseBody?.count == 1)
        
        let dict = responseBody?[0]
        let record = records[1].breakTimes[0]
        #expect(dict?["id"] as? String == record.id.uuidString)
        #expect(dict?["start"] as? Double == record.start?.timeIntervalSinceReferenceDate)
        #expect(dict?["end"] as? Double == record.end?.timeIntervalSinceReferenceDate)
    }
    
    @Test mutating func testGetBreakTime_wrongId() async throws {
        let uri = "timecard/breaktime/id"
        try runTest(method: .GET, uri: uri, body: "")
        #expect(responseHead?.status == .badRequest)
    }
    
    @Test mutating func testGetBreakTime_missingId() async throws {
        let uri = "timecard/breaktime"
        try runTest(method: .GET, uri: uri, body: "")
        #expect(responseHead?.status == .badRequest)
    }
    
    @Test mutating func testGetBreakTime_tooManyPath() async throws {
        let uri = "timecard/breaktime/\(records[1].breakTimes[0].id.uuidString)/redundant"
        try runTest(method: .GET, uri: uri, body: "")
        #expect(responseHead?.status == .badRequest)
    }
    
    @Test mutating func testPutBreakTime() async throws {
        let uri = "timecard/breaktime/\(records[1].breakTimes[0].id.uuidString)"
        let start = date(2025, 10, 18, 11, 30, 0)?.timeIntervalSinceReferenceDate ?? 0
        let end = date(2025, 10, 18, 12, 15, 0)?.timeIntervalSinceReferenceDate ?? 0
        let body = """
            {
                "start":    \(start),
                "end":      \(end)
            }
            """
        try runTest(method: .PUT, uri: uri, body: body)
        #expect(responseHead?.status == .ok)
        #expect(responseHead?.headers.first(name: "Content-Type") == "application/json")
        
        #expect(records[0].breakTimes[0].start?.day == 15)
        #expect(records[0].breakTimes[0].end?.day == 15)
        #expect(records[1].breakTimes[0].start?.timeIntervalSinceReferenceDate == start)
        #expect(records[1].breakTimes[0].end?.timeIntervalSinceReferenceDate == end)
        #expect(records[1].breakTimes[1].start?.hour == 17)
        #expect(records[1].breakTimes[1].end?.hour == 18)
        
        #expect(responseBody?.count == 1)
        
        let dict = responseBody?[0]
        let record = records[1].breakTimes[0]
        #expect(dict?["id"] as? String == record.id.uuidString)
        #expect(dict?["start"] as? Double == record.start?.timeIntervalSinceReferenceDate)
        #expect(dict?["end"] as? Double == record.end?.timeIntervalSinceReferenceDate)
    }
    
    @Test mutating func testPutBreakTime_wrongBody() async throws {
        let uri = "timecard/breaktime/\(records[1].breakTimes[0].id.uuidString)"
        let start = date(2025, 10, 18, 11, 30, 0)?.timeIntervalSinceReferenceDate ?? 0
        let end = date(2025, 10, 18, 12, 15, 0)?.timeIntervalSinceReferenceDate ?? 0
        let body = """
            {
                "start":    \(start),
                "end":      \(end),
                wrongKey:   wrongValue
            }
            """
        try runTest(method: .PUT, uri: uri, body: body)
        #expect(responseHead?.status == .badRequest)
        
        #expect(records[1].breakTimes[0].start?.hour == 12)
        #expect(records[1].breakTimes[0].end?.hour == 13)
    }
    
    @Test mutating func testPutBreakTime_missingParameter() async throws {
        let uri = "timecard/breaktime/\(records[1].breakTimes[0].id.uuidString)"
        let start = date(2025, 10, 18, 11, 30, 0)?.timeIntervalSinceReferenceDate ?? 0
        let body = """
            {
                "start":    \(start)
            }
            """
        try runTest(method: .PUT, uri: uri, body: body)
        #expect(responseHead?.status == .badRequest)
        
        #expect(records[1].breakTimes[0].start?.hour == 12)
        #expect(records[1].breakTimes[0].end?.hour == 13)
    }
    
    @Test mutating func testPutBreakTime_wrongId() async throws {
        let uri = "timecard/breaktime/\(UUID().uuidString)"
        let start = date(2025, 10, 18, 11, 30, 0)?.timeIntervalSinceReferenceDate ?? 0
        let end = date(2025, 10, 18, 12, 15, 0)?.timeIntervalSinceReferenceDate ?? 0
        let body = """
            {
                "start":    \(start),
                "end":      \(end)
            }
            """
        try runTest(method: .PUT, uri: uri, body: body)
        #expect(responseHead?.status == .notFound)
        
        #expect(records[1].breakTimes[0].start?.hour == 12)
        #expect(records[1].breakTimes[0].end?.hour == 13)
    }
    
    @Test mutating func testPutBreakTime_missingId() async throws {
        let uri = "timecard/breaktime/"
        let start = date(2025, 10, 18, 11, 30, 0)?.timeIntervalSinceReferenceDate ?? 0
        let end = date(2025, 10, 18, 12, 15, 0)?.timeIntervalSinceReferenceDate ?? 0
        let body = """
            {
                "start":    \(start),
                "end":      \(end)
            }
            """
        try runTest(method: .PUT, uri: uri, body: body)
        #expect(responseHead?.status == .badRequest)
        
        #expect(records[1].breakTimes[0].start?.hour == 12)
        #expect(records[1].breakTimes[0].end?.hour == 13)
    }
}
