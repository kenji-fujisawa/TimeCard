//
//  TimeRecordRepositoryTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2026/01/14.
//

import Foundation
import SwiftData
import Testing

@testable import TimeCard

struct TimeRecordRepositoryTests {

    private let container: ModelContainer
    private let context: ModelContext
    
    init() throws {
        let schema = Schema(versionedSchema: TimeCardSchema_v3.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        self.container = try ModelContainer(for: schema, configurations: config)
        self.context = ModelContext(container)
    }
    
    @Test func testGetRecords() async throws {
        let source = FakeLocalDataSource()
        let repository = DefaultTimeRecordRepository(source)
        let result = try repository.getRecords(year: Date.now.year, month: Date.now.month)
        #expect(result == source.records)
    }
    
    @Test func testGetRecord() async throws {
        let source = FakeLocalDataSource()
        let repository = DefaultTimeRecordRepository(source)
        let result = try repository.getRecord(id: UUID())
        #expect(result == source.records[0])
    }
    
    @Test func testGetBreakTime() async throws {
        let source = FakeLocalDataSource()
        let repository = DefaultTimeRecordRepository(source)
        let result = try repository.getBreakTime(id: UUID())
        #expect(result == source.records[0].breakTimes[0])
    }
    
    @Test func testInsert() async throws {
        let source = FakeLocalDataSource()
        let repository = DefaultTimeRecordRepository(source)
        
        let record = TimeRecord()
        try repository.insert(record)
        #expect(source.inserted == record)
    }
    
    @Test func testUpdate() async throws {
        let source = FakeLocalDataSource()
        let repository = DefaultTimeRecordRepository(source)
        
        let record = TimeRecord()
        try repository.update(record)
        #expect(source.updated == record)
    }
    
    @Test func testDelete() async throws {
        let source = FakeLocalDataSource()
        let repository = DefaultTimeRecordRepository(source)
        
        let record = TimeRecord()
        try repository.delete(record)
        #expect(source.deleted == record)
    }
    
    @Test func testGetState() async throws {
        let source = DefaultLocalDataSource(context)
        let repository = DefaultTimeRecordRepository(source)
        
        var state = repository.getState()
        #expect(state == .offWork)
        
        let now = Date.now
        var record = LocalTimeRecord(year: now.year, month: now.month)
        context.insert(record)
        
        state = repository.getState()
        #expect(state == .offWork)
        
        record.checkIn = now
        
        state = repository.getState()
        #expect(state == .atWork)
        
        record.breakTimes.append(LocalTimeRecord.BreakTime())
        
        state = repository.getState()
        #expect(state == .atWork)
        
        record.breakTimes[0].start = now
        
        state = repository.getState()
        #expect(state == .atBreak)
        
        record.breakTimes[0].end = now
        
        state = repository.getState()
        #expect(state == .atWork)
        
        record.checkOut = now
        
        state = repository.getState()
        #expect(state == .offWork)
        
        record = LocalTimeRecord(year: now.year, month: now.month, checkIn: now.addingTimeInterval(1))
        context.insert(record)
        
        state = repository.getState()
        #expect(state == .atWork)
    }
    
    @Test func testCheckIn() async throws {
        let source = DefaultLocalDataSource(context)
        let repository = DefaultTimeRecordRepository(source)
        
        try repository.checkIn()
        
        let descriptor = FetchDescriptor<LocalTimeRecord>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].year == Date.now.year)
        #expect(results[0].month == Date.now.month)
        #expect(results[0].checkIn?.equals(.now) == true)
        #expect(results[0].checkOut == nil)
        #expect(results[0].breakTimes.count == 0)
    }
    
    @Test func testCheckIn_fail() async throws {
        let source = DefaultLocalDataSource(context)
        let repository = DefaultTimeRecordRepository(source)
        
        let now = Date.now
        let record = LocalTimeRecord(year: now.year, month: now.month, checkIn: now)
        context.insert(record)
        
        #expect(throws: DefaultTimeRecordRepository.TimeRecordError.stateMismatch) {
            try repository.checkIn()
        }
        
        record.breakTimes.append(LocalTimeRecord.BreakTime(start: now))
        
        #expect(throws: DefaultTimeRecordRepository.TimeRecordError.stateMismatch) {
            try repository.checkIn()
        }
    }
    
    @Test func testCheckOut() async throws {
        let source = DefaultLocalDataSource(context)
        let repository = DefaultTimeRecordRepository(source)
        
        let now = Date.now
        let record = LocalTimeRecord(year: now.year, month: now.month, checkIn: now)
        context.insert(record)
        
        try repository.checkOut()
        
        let descriptor = FetchDescriptor<LocalTimeRecord>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].year == now.year)
        #expect(results[0].month == now.month)
        #expect(results[0].checkIn?.equals(.now) == true)
        #expect(results[0].checkOut?.equals(.now) == true)
        #expect(results[0].breakTimes.count == 0)
    }
    
    @Test func testCheckOut_fail() async throws {
        let source = DefaultLocalDataSource(context)
        let repository = DefaultTimeRecordRepository(source)
        
        #expect(throws: DefaultTimeRecordRepository.TimeRecordError.stateMismatch) {
            try repository.checkOut()
        }
        
        let now = Date.now
        let record = LocalTimeRecord(year: now.year, month: now.month, checkIn: now)
        record.breakTimes.append(LocalTimeRecord.BreakTime(start: now))
        context.insert(record)
        
        #expect(throws: DefaultTimeRecordRepository.TimeRecordError.stateMismatch) {
            try repository.checkOut()
        }
    }
    
    @Test func testStartBreak() async throws {
        let source = DefaultLocalDataSource(context)
        let repository = DefaultTimeRecordRepository(source)
        
        let now = Date.now
        let record = LocalTimeRecord(year: now.year, month: now.month, checkIn: now)
        context.insert(record)
        
        try repository.startBreak()
        
        let descriptor = FetchDescriptor<LocalTimeRecord>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].breakTimes.count == 1)
        #expect(results[0].breakTimes[0].start?.equals(.now) == true)
        #expect(results[0].breakTimes[0].end == nil)
    }
    
    @Test func testStartBreak_fail() async throws {
        let source = DefaultLocalDataSource(context)
        let repository = DefaultTimeRecordRepository(source)
        
        #expect(throws: DefaultTimeRecordRepository.TimeRecordError.stateMismatch) {
            try repository.startBreak()
        }
        
        let now = Date.now
        let record = LocalTimeRecord(year: now.year, month: now.month, checkIn: now)
        record.breakTimes.append(LocalTimeRecord.BreakTime(start: now))
        context.insert(record)
        
        #expect(throws: DefaultTimeRecordRepository.TimeRecordError.stateMismatch) {
            try repository.startBreak()
        }
    }
    
    @Test func testEndBreak() async throws {
        let source = DefaultLocalDataSource(context)
        let repository = DefaultTimeRecordRepository(source)
        
        let now = Date.now
        let record = LocalTimeRecord(year: now.year, month: now.month, checkIn: now)
        record.breakTimes.append(LocalTimeRecord.BreakTime(start: now))
        context.insert(record)
        
        try repository.endBreak()
        
        let descriptor = FetchDescriptor<LocalTimeRecord>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].breakTimes.count == 1)
        #expect(results[0].breakTimes[0].start?.equals(.now) == true)
        #expect(results[0].breakTimes[0].end?.equals(.now) == true)
    }
    
    @Test func testEndBreak_fail() async throws {
        let source = DefaultLocalDataSource(context)
        let repository = DefaultTimeRecordRepository(source)
        
        #expect(throws: DefaultTimeRecordRepository.TimeRecordError.stateMismatch) {
            try repository.endBreak()
        }
        
        let now = Date.now
        let record = LocalTimeRecord(year: now.year, month: now.month, checkIn: now)
        context.insert(record)
        
        #expect(throws: DefaultTimeRecordRepository.TimeRecordError.stateMismatch) {
            try repository.endBreak()
        }
    }
    
    class FakeLocalDataSource: LocalDataSource {
        let records = [
            TimeRecord(
                checkIn: .now,
                checkOut: .now,
                breakTimes: [
                    TimeRecord.BreakTime(
                        start: .now,
                        end: .now
                    )
                ]
            )
        ]
        
        func getTimeRecord(id: UUID) throws -> TimeRecord? {
            records[0]
        }
        
        func getBreakTime(id: UUID) throws -> TimeRecord.BreakTime? {
            records[0].breakTimes[0]
        }
        
        func getTimeRecords(year: Int, month: Int) throws -> [TimeRecord] {
            records
        }
        
        var inserted: TimeRecord? = nil
        func insertTimeRecord(_ record: TimeRecord) throws {
            inserted = record
        }
        
        var updated: TimeRecord? = nil
        func updateTimeRecord(_ record: TimeRecord) throws {
            updated = record
        }
        
        var deleted: TimeRecord? = nil
        func deleteTimeRecord(_ record: TimeRecord) throws {
            deleted = record
        }
        
        func getUptimeRecords(year: Int, month: Int) throws -> [SystemUptimeRecord] { [] }
        func insertUptimeRecord(_ record: SystemUptimeRecord) throws {}
        func updateUptimeRecord(_ record: SystemUptimeRecord) throws {}
        func deleteUptimeRecord(_ record: SystemUptimeRecord) throws {}
    }
}

private extension Date {
    func equals(_ date: Date) -> Bool {
        abs(self.distance(to: date)) < 1
    }
}
