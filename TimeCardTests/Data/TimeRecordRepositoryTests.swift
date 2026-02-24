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
    
    @Test func testGetState() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultTimeRecordRepository(source: source)
        
        var state = repository.getState()
        #expect(state == .OffWork)
        
        let now = Date.now
        var record = TimeRecord(year: now.year, month: now.month)
        context.insert(record)
        
        state = repository.getState()
        #expect(state == .OffWork)
        
        record.checkIn = now
        
        state = repository.getState()
        #expect(state == .AtWork)
        
        record.breakTimes.append(TimeRecord.BreakTime())
        
        state = repository.getState()
        #expect(state == .AtWork)
        
        record.breakTimes[0].start = now
        
        state = repository.getState()
        #expect(state == .AtBreak)
        
        record.breakTimes[0].end = now
        
        state = repository.getState()
        #expect(state == .AtWork)
        
        record.checkOut = now
        
        state = repository.getState()
        #expect(state == .OffWork)
        
        record = TimeRecord(year: now.year, month: now.month, checkIn: now.addingTimeInterval(1))
        context.insert(record)
        
        state = repository.getState()
        #expect(state == .AtWork)
    }
    
    @Test func testCheckIn() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultTimeRecordRepository(source: source)
        
        try repository.checkIn()
        
        let descriptor = FetchDescriptor<TimeRecord>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].year == Date.now.year)
        #expect(results[0].month == Date.now.month)
        #expect(results[0].checkIn?.equals(.now) == true)
        #expect(results[0].checkOut == nil)
        #expect(results[0].breakTimes.count == 0)
    }
    
    @Test func testCheckIn_fail() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultTimeRecordRepository(source: source)
        
        let now = Date.now
        let record = TimeRecord(year: now.year, month: now.month, checkIn: now)
        context.insert(record)
        
        #expect(throws: DefaultTimeRecordRepository.TimeRecordError.stateMismatch) {
            try repository.checkIn()
        }
        
        record.breakTimes.append(TimeRecord.BreakTime(start: now))
        
        #expect(throws: DefaultTimeRecordRepository.TimeRecordError.stateMismatch) {
            try repository.checkIn()
        }
    }
    
    @Test func testCheckOut() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultTimeRecordRepository(source: source)
        
        let now = Date.now
        let record = TimeRecord(year: now.year, month: now.month, checkIn: now)
        context.insert(record)
        
        try repository.checkOut()
        
        let descriptor = FetchDescriptor<TimeRecord>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].year == now.year)
        #expect(results[0].month == now.month)
        #expect(results[0].checkIn?.equals(.now) == true)
        #expect(results[0].checkOut?.equals(.now) == true)
        #expect(results[0].breakTimes.count == 0)
    }
    
    @Test func testCheckOut_fail() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultTimeRecordRepository(source: source)
        
        #expect(throws: DefaultTimeRecordRepository.TimeRecordError.stateMismatch) {
            try repository.checkOut()
        }
        
        let now = Date.now
        let record = TimeRecord(year: now.year, month: now.month, checkIn: now)
        record.breakTimes.append(TimeRecord.BreakTime(start: now))
        context.insert(record)
        
        #expect(throws: DefaultTimeRecordRepository.TimeRecordError.stateMismatch) {
            try repository.checkOut()
        }
    }
    
    @Test func testStartBreak() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultTimeRecordRepository(source: source)
        
        let now = Date.now
        let record = TimeRecord(year: now.year, month: now.month, checkIn: now)
        context.insert(record)
        
        try repository.startBreak()
        
        let descriptor = FetchDescriptor<TimeRecord>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].breakTimes.count == 1)
        #expect(results[0].breakTimes[0].start?.equals(.now) == true)
        #expect(results[0].breakTimes[0].end == nil)
    }
    
    @Test func testStartBreak_fail() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultTimeRecordRepository(source: source)
        
        #expect(throws: DefaultTimeRecordRepository.TimeRecordError.stateMismatch) {
            try repository.startBreak()
        }
        
        let now = Date.now
        let record = TimeRecord(year: now.year, month: now.month, checkIn: now)
        record.breakTimes.append(TimeRecord.BreakTime(start: now))
        context.insert(record)
        
        #expect(throws: DefaultTimeRecordRepository.TimeRecordError.stateMismatch) {
            try repository.startBreak()
        }
    }
    
    @Test func testEndBreak() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultTimeRecordRepository(source: source)
        
        let now = Date.now
        let record = TimeRecord(year: now.year, month: now.month, checkIn: now)
        record.breakTimes.append(TimeRecord.BreakTime(start: now))
        context.insert(record)
        
        try repository.endBreak()
        
        let descriptor = FetchDescriptor<TimeRecord>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].breakTimes.count == 1)
        #expect(results[0].breakTimes[0].start?.equals(.now) == true)
        #expect(results[0].breakTimes[0].end?.equals(.now) == true)
    }
    
    @Test func testEndBreak_fail() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultTimeRecordRepository(source: source)
        
        #expect(throws: DefaultTimeRecordRepository.TimeRecordError.stateMismatch) {
            try repository.endBreak()
        }
        
        let now = Date.now
        let record = TimeRecord(year: now.year, month: now.month, checkIn: now)
        context.insert(record)
        
        #expect(throws: DefaultTimeRecordRepository.TimeRecordError.stateMismatch) {
            try repository.endBreak()
        }
    }
}

private extension Date {
    func equals(_ date: Date) -> Bool {
        abs(self.distance(to: date)) < 1
    }
}
