//
//  LocalDataSourceTests.swift
//  TimeCardClientIOSTests
//
//  Created by uhimania on 2026/01/07.
//

import Foundation
import SwiftData
import Testing

@testable import TimeCardClientIOS

struct LocalDataSourceTests {

    private let container: ModelContainer
    private let context: ModelContext
    private let formatter: DateFormatter
    private let records: [TimeRecord]
    
    init() throws {
        let schema = Schema([LocalTimeRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        self.container = try ModelContainer(for: schema, configurations: config)
        self.context = ModelContext(container)
        
        self.formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        self.records = [
            TimeRecord(
                id: UUID(),
                year: 2025,
                month: 12,
                checkIn: formatter.date(from: "2025-12-29 08:00:00"),
                checkOut: formatter.date(from: "2025-12-29 18:00:00"),
                breakTimes: [
                    TimeRecord.BreakTime(
                        id: UUID(),
                        start: formatter.date(from: "2025-12-29 12:00:00"),
                        end: formatter.date(from: "2025-12-29 12:30:00")
                    ),
                    TimeRecord.BreakTime(
                        id: UUID(),
                        start: formatter.date(from: "2025-12-29 15:00:00"),
                        end: formatter.date(from: "2025-12-29 15:15:00")
                    )
                ]
            ),
            TimeRecord(
                id: UUID(),
                year: 2025,
                month: 12,
                checkIn: formatter.date(from: "2025-12-30 09:00:00"),
                checkOut: nil,
                breakTimes: []
            ),
            TimeRecord(
                id: UUID(),
                year: 2026,
                month: 1,
                checkIn: formatter.date(from: "2026-01-07 08:30:00"),
                checkOut: nil,
                breakTimes: [
                    TimeRecord.BreakTime(
                        id: UUID(),
                        start: formatter.date(from: "2026-01-07 12:30:00"),
                        end: nil
                    )
                ]
            )
        ]
    }
    
    @Test func testGetRecords() async throws {
        records.forEach { context.insert($0.asLocal()) }
        
        let source = DefaultLocalDataSource(context)
        var results = try source.getRecords(year: 2025, month: 12)
        #expect(results.count == 2)
        #expect(results[0] == records[0])
        #expect(results[1] == records[1])
        
        results = try source.getRecords(year: 2026, month: 1)
        #expect(results.count == 1)
        #expect(results[0] == records[2])
        
        results = try source.getRecords(year: 2026, month: 2)
        #expect(results.count == 0)
    }

    @Test func testInsertRecord() async throws {
        let source = DefaultLocalDataSource(context)
        try records.forEach { try source.insertRecord($0) }
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            sortBy: [.init(\.checkIn)]
        )
        let results = try context.fetch(descriptor).map { $0.asTimeRecord() }
        #expect(results.count == 3)
        #expect(results[0] == records[0])
        #expect(results[1] == records[1])
        #expect(results[2] == records[2])
    }
    
    @Test func testUpdateRecord() async throws {
        records.forEach { context.insert($0.asLocal()) }
        
        var record = records[1]
        record.checkOut = formatter.date(from: "2025-12-30 19:00:00")
        record.breakTimes = [
            TimeRecord.BreakTime(
                id: UUID(),
                start: formatter.date(from: "2025-12-30 13:00:00"),
                end: formatter.date(from: "2025-12-30 13:30:00")
            ),
            TimeRecord.BreakTime(
                id: UUID(),
                start: formatter.date(from: "2025-12-30 18:00:00"),
                end: nil
            )
        ]
        
        let source = DefaultLocalDataSource(context)
        try source.updateRecord(record)
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            sortBy: [.init(\.checkIn)]
        )
        let results = try context.fetch(descriptor).map { $0.asTimeRecord() }
        #expect(results.count == 3)
        #expect(results[0] == records[0])
        #expect(results[2] == records[2])
        
        #expect(results[1].id == records[1].id)
        #expect(results[1].year == records[1].year)
        #expect(results[1].month == records[1].month)
        #expect(results[1].checkIn == records[1].checkIn)
        #expect(results[1].checkOut != records[1].checkOut)
        #expect(results[1].breakTimes.count != records[1].breakTimes.count)
        
        #expect(results[1].checkOut == record.checkOut)
        #expect(results[1].breakTimes.count == 2)
        #expect(results[1].breakTimes[0] == record.breakTimes[0])
        #expect(results[1].breakTimes[1] == record.breakTimes[1])
    }
    
    @Test func testDeleteRecord() async throws {
        records.forEach { context.insert($0.asLocal()) }
        
        let source = DefaultLocalDataSource(context)
        try source.deleteRecord(records[1])
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            sortBy: [.init(\.checkIn)]
        )
        var results = try context.fetch(descriptor).map { $0.asTimeRecord() }
        #expect(results.count == 2)
        #expect(results[0] == records[0])
        #expect(results[1] == records[2])
        
        try source.deleteRecord(records[0])
        try source.deleteRecord(records[2])
        
        results = try context.fetch(descriptor).map { $0.asTimeRecord() }
        #expect(results.count == 0)
        
        let breakTimes = try context.fetch(FetchDescriptor<LocalTimeRecord.LocalBreakTime>())
        #expect(breakTimes.count == 0)
    }
    
    @Test func testDeleteRecords() async throws {
        records.forEach { context.insert($0.asLocal()) }
        
        let source = DefaultLocalDataSource(context)
        try source.deleteRecords(year: 2025, month: 12)
        
        var results = try context.fetch(FetchDescriptor<LocalTimeRecord>()).map { $0.asTimeRecord() }
        #expect(results.count == 1)
        #expect(results[0] == records[2])
        
        var breakTimes = try context.fetch(FetchDescriptor<LocalTimeRecord.LocalBreakTime>()).map { $0.asBreakTime() }
        #expect(breakTimes.count == 1)
        #expect(breakTimes[0] == records[2].breakTimes[0])
        
        try source.deleteRecords(year: 2026, month: 1)
        
        results = try context.fetch(FetchDescriptor<LocalTimeRecord>()).map { $0.asTimeRecord() }
        #expect(results.count == 0)
        
        breakTimes = try context.fetch(FetchDescriptor<LocalTimeRecord.LocalBreakTime>()).map { $0.asBreakTime() }
        #expect(breakTimes.count == 0)
    }
}
