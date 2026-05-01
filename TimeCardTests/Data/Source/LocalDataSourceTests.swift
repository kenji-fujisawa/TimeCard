//
//  LocalDataSourceTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2026/01/13.
//

import Foundation
import SwiftData
import Testing

@testable import TimeCard

struct LocalDataSourceTests {

    private let container: ModelContainer
    private let context: ModelContext
    private let formatter: DateFormatter
    private let timeRecords: [TimeRecord]
    private let uptimeRecords: [SystemUptimeRecord]
    
    init() throws {
        let schema = Schema(versionedSchema: TimeCardSchema_v3.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        self.container = try ModelContainer(for: schema, configurations: config)
        self.context = ModelContext(container)
        
        formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        self.timeRecords = [
            TimeRecord(
                checkIn: formatter.date(from: "2025-12-29 08:00:00"),
                checkOut: formatter.date(from: "2025-12-29 18:00:00"),
                breakTimes: [
                    TimeRecord.BreakTime(
                        start: formatter.date(from: "2025-12-29 12:00:00"),
                        end: formatter.date(from: "2025-12-29 12:30:00")
                    ),
                    TimeRecord.BreakTime(
                        start: formatter.date(from: "2025-12-29 15:00:00"),
                        end: formatter.date(from: "2025-12-29 15:15:00")
                    )
                ]
            ),
            TimeRecord(
                checkIn: formatter.date(from: "2025-12-30 09:00:00"),
                checkOut: nil,
                breakTimes: []
            ),
            TimeRecord(
                checkIn: formatter.date(from: "2026-01-07 08:30:00"),
                checkOut: nil,
                breakTimes: [
                    TimeRecord.BreakTime(
                        start: formatter.date(from: "2026-01-07 12:30:00"),
                        end: nil
                    )
                ]
            )
        ]
        
        uptimeRecords = [
            SystemUptimeRecord(
                launch: formatter.date(from: "2025-12-29 07:00:00") ?? .now,
                shutdown: formatter.date(from: "2025-12-29 19:00:00") ?? .now,
                sleepRecords: [
                    SystemUptimeRecord.SleepRecord(
                        start: formatter.date(from: "2025-12-29 12:00:00") ?? .now,
                        end: formatter.date(from: "2025-12-29 13:00:00") ?? .now
                    ),
                    SystemUptimeRecord.SleepRecord(
                        start: formatter.date(from: "2025-12-29 15:00:00") ?? .now,
                        end: formatter.date(from: "2025-12-29 15:30:00") ?? .now
                    )
                ]
            ),
            SystemUptimeRecord(
                launch: formatter.date(from: "2025-12-30 08:00:00") ?? .now,
                shutdown: formatter.date(from: "2025-12-30 20:00:00") ?? .now,
                sleepRecords: []
            ),
            SystemUptimeRecord(
                launch: formatter.date(from: "2026-01-07 07:30:00") ?? .now,
                shutdown: formatter.date(from: "2026-01-07 20:30:00") ?? .now,
                sleepRecords: [
                    SystemUptimeRecord.SleepRecord(
                        start: formatter.date(from: "2026-01-07 12:30:00") ?? .now,
                        end: formatter.date(from: "2026-01-07 13:30:00") ?? .now
                    )
                ]
            )
        ]
    }
    
    @Test func testGetTimeRecord() async throws {
        timeRecords.forEach { context.insert($0.asLocal()) }
        
        let source = DefaultLocalDataSource(context)
        var result = try source.getTimeRecord(id: timeRecords[0].id)
        #expect(result == timeRecords[0])
        
        result = try source.getTimeRecord(id: timeRecords[2].id)
        #expect(result == timeRecords[2])
        
        result = try source.getTimeRecord(id: UUID())
        #expect(result == nil)
    }
    
    @Test func testGetBreakTime() async throws {
        timeRecords.forEach { context.insert($0.asLocal()) }
        
        let source = DefaultLocalDataSource(context)
        var result = try source.getBreakTime(id: timeRecords[0].breakTimes[1].id)
        #expect(result == timeRecords[0].breakTimes[1])
        
        result = try source.getBreakTime(id: timeRecords[2].breakTimes[0].id)
        #expect(result == timeRecords[2].breakTimes[0])
        
        result = try source.getBreakTime(id: UUID())
        #expect(result == nil)
    }
    
    @Test func testGetTimeRecords() async throws {
        timeRecords.forEach { context.insert($0.asLocal()) }
        
        let source = DefaultLocalDataSource(context)
        var results = try source.getTimeRecords()
        #expect(results.count == 3)
        #expect(results[0] == timeRecords[0])
        #expect(results[1] == timeRecords[1])
        #expect(results[2] == timeRecords[2])
        
        results = try source.getTimeRecords(year: 2025, month: 12)
        #expect(results.count == 2)
        #expect(results[0] == timeRecords[0])
        #expect(results[1] == timeRecords[1])
        
        results = try source.getTimeRecords(year: 2026, month: 1)
        #expect(results.count == 1)
        #expect(results[0] == timeRecords[2])
        
        results = try source.getTimeRecords(year: 2026, month: 2)
        #expect(results.count == 0)
    }
    
    @Test func testInsertTimeRecord() async throws {
        let source = DefaultLocalDataSource(context)
        try timeRecords.forEach { try source.insertTimeRecord($0) }
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            sortBy: [.init(\.checkIn)]
        )
        let results = try context.fetch(descriptor).map { $0.asTimeRecord() }
        #expect(results.count == 3)
        #expect(results[0] == timeRecords[0])
        #expect(results[1] == timeRecords[1])
        #expect(results[2] == timeRecords[2])
    }
    
    @Test func testUpdateTimeRecord() async throws {
        timeRecords.forEach { context.insert($0.asLocal()) }
        
        let source = DefaultLocalDataSource(context)
        var records = try source.getTimeRecords(year: 2025, month: 12)
        
        records[1].checkOut = formatter.date(from: "2025-12-30 19:30:00")
        records[1].breakTimes.append(TimeRecord.BreakTime(
            start: formatter.date(from: "2025-12-30 13:00:00")
        ))
        
        records[0].breakTimes[1].end = nil
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.year == 2025 && $0.month == 12 },
            sortBy: [.init(\.checkIn)]
        )
        var results = try context.fetch(descriptor).map { $0.asTimeRecord() }
        #expect(results.count == 2)
        #expect(results[0] != records[0])
        #expect(results[1] != records[1])
        
        try source.updateTimeRecord(records[0])
        try source.updateTimeRecord(records[1])
        
        results = try context.fetch(descriptor).map { $0.asTimeRecord() }
        #expect(results.count == 2)
        #expect(results[0] == records[0])
        #expect(results[1] == records[1])
        
        #expect(results[1].checkIn == formatter.date(from: "2025-12-30 09:00:00"))
        #expect(results[1].checkOut == formatter.date(from: "2025-12-30 19:30:00"))
        #expect(results[1].breakTimes.count == 1)
        #expect(results[1].breakTimes[0].start == formatter.date(from: "2025-12-30 13:00:00"))
        #expect(results[1].breakTimes[0].end == nil)
        
        #expect(results[0].breakTimes.count == 2)
        #expect(results[0].breakTimes[0].start == formatter.date(from: "2025-12-29 12:00:00"))
        #expect(results[0].breakTimes[0].end == formatter.date(from: "2025-12-29 12:30:00"))
        #expect(results[0].breakTimes[1].start == formatter.date(from: "2025-12-29 15:00:00"))
        #expect(results[0].breakTimes[1].end == nil)
    }
    
    @Test func testDeleteTimeRecord() async throws {
        timeRecords.forEach { context.insert($0.asLocal()) }
        
        let source = DefaultLocalDataSource(context)
        let records = try source.getTimeRecords(year: 2025, month: 12)
        
        try source.deleteTimeRecord(records[0])
        
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            sortBy: [.init(\.checkIn)]
        )
        let timeRecords = try context.fetch(descriptor).map { $0.asTimeRecord() }
        #expect(timeRecords.count == 2)
        #expect(timeRecords[0] == self.timeRecords[1])
        #expect(timeRecords[1] == self.timeRecords[2])
        
        let breakTimes = try context.fetch(FetchDescriptor<LocalTimeRecord.BreakTime>()).map { $0.asBreakTime() }
        #expect(breakTimes.count == 1)
        #expect(breakTimes[0] == self.timeRecords[2].breakTimes[0])
    }
    
    @Test func testGetUptimeRecords() async throws {
        uptimeRecords.forEach { context.insert($0.asLocal()) }
        
        let source = DefaultLocalDataSource(context)
        var results = try source.getUptimeRecords(year: 2025, month: 12)
        #expect(results.count == 2)
        #expect(results[0] == uptimeRecords[0])
        #expect(results[1] == uptimeRecords[1])
        
        results = try source.getUptimeRecords(year: 2026, month: 1)
        #expect(results.count == 1)
        #expect(results[0] == uptimeRecords[2])
        
        results = try source.getUptimeRecords(year: 2026, month: 2)
        #expect(results.count == 0)
    }
    
    @Test func testGetUptimeRecord() async throws {
        uptimeRecords.forEach { context.insert($0.asLocal()) }
        
        let source = DefaultLocalDataSource(context)
        var result = try source.getUptimeRecord(id: uptimeRecords[0].id)
        #expect(result == uptimeRecords[0])
        
        result = try source.getUptimeRecord(id: uptimeRecords[1].id)
        #expect(result == uptimeRecords[1])
        
        result = try source.getUptimeRecord(id: uptimeRecords[2].id)
        #expect(result == uptimeRecords[2])
        
        result = try source.getUptimeRecord(id: UUID())
        #expect(result == nil)
    }
    
    @Test func testInsertUptimeRecord() async throws {
        let source = DefaultLocalDataSource(context)
        try uptimeRecords.forEach { try source.insertUptimeRecord($0) }
        
        let descriptor = FetchDescriptor<LocalUptimeRecord>(
            sortBy: [.init(\.launch)]
        )
        let results = try context.fetch(descriptor).map { $0.asUptimeRecord() }
        #expect(results.count == 3)
        #expect(results[0] == uptimeRecords[0])
        #expect(results[1] == uptimeRecords[1])
        #expect(results[2] == uptimeRecords[2])
    }
    
    @Test func testUpdateUptimeRecord() async throws {
        uptimeRecords.forEach { context.insert($0.asLocal()) }
        
        let source = DefaultLocalDataSource(context)
        var records = try source.getUptimeRecords(year: 2025, month: 12)
        
        records[1].shutdown = formatter.date(from: "2025-12-30 19:30:00") ?? .now
        records[1].sleepRecords.append(SystemUptimeRecord.SleepRecord(
            start: formatter.date(from: "2025-12-30 13:00:00") ?? .now,
            end: formatter.date(from: "2025-12-30 13:30:00") ?? .now
        ))
        
        records[0].sleepRecords[1].end = formatter.date(from: "2025-12-29 16:00:00") ?? .now
        
        let descriptor = FetchDescriptor<LocalUptimeRecord>(
            predicate: #Predicate { $0.year == 2025 && $0.month == 12 },
            sortBy: [.init(\.launch)]
        )
        var results = try context.fetch(descriptor).map { $0.asUptimeRecord() }
        #expect(results.count == 2)
        #expect(results[0] != records[0])
        #expect(results[1] != records[1])
        
        try source.updateUptimeRecord(records[0])
        try source.updateUptimeRecord(records[1])
        
        results = try context.fetch(descriptor).map { $0.asUptimeRecord() }
        #expect(results.count == 2)
        #expect(results[0] == records[0])
        #expect(results[1] == records[1])
        
        #expect(results[1].launch == formatter.date(from: "2025-12-30 08:00:00"))
        #expect(results[1].shutdown == formatter.date(from: "2025-12-30 19:30:00"))
        #expect(results[1].sleepRecords.count == 1)
        #expect(results[1].sleepRecords[0].start == formatter.date(from: "2025-12-30 13:00:00"))
        #expect(results[1].sleepRecords[0].end == formatter.date(from: "2025-12-30 13:30:00"))
        
        #expect(results[0].sleepRecords.count == 2)
        #expect(results[0].sleepRecords[0].start == formatter.date(from: "2025-12-29 12:00:00"))
        #expect(results[0].sleepRecords[0].end == formatter.date(from: "2025-12-29 13:00:00"))
        #expect(results[0].sleepRecords[1].start == formatter.date(from: "2025-12-29 15:00:00"))
        #expect(results[0].sleepRecords[1].end == formatter.date(from: "2025-12-29 16:00:00"))
    }
    
    @Test func testDeleteUptimeRecord() async throws {
        uptimeRecords.forEach { context.insert($0.asLocal()) }
        
        let source = DefaultLocalDataSource(context)
        let records = try source.getUptimeRecords(year: 2025, month: 12)
        
        try source.deleteUptimeRecord(records[0])
        
        let descriptor = FetchDescriptor<LocalUptimeRecord>(
            sortBy: [.init(\.launch)]
        )
        let uptimeRecords = try context.fetch(descriptor).map { $0.asUptimeRecord() }
        #expect(uptimeRecords.count == 2)
        #expect(uptimeRecords[0] == self.uptimeRecords[1])
        #expect(uptimeRecords[1] == self.uptimeRecords[2])
        
        let sleepRecords = try context.fetch(FetchDescriptor<LocalUptimeRecord.SleepRecord>()).map { $0.asSleepRecord() }
        #expect(sleepRecords.count == 1)
        #expect(sleepRecords[0] == self.uptimeRecords[2].sleepRecords[0])
    }
}
