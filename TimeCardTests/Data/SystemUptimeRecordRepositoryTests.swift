//
//  SystemUptimeRecordRepositoryTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2026/01/17.
//

import Foundation
import SwiftData
import Testing

@testable import TimeCard

struct SystemUptimeRecordRepositoryTests {

    private let container: ModelContainer
    private let context: ModelContext
    
    init() throws {
        let schema = Schema(versionedSchema: TimeCardSchema_v3.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        self.container = try ModelContainer(for: schema, configurations: config)
        self.context = ModelContext(container)
    }
    
    @Test func testLaunch() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultSystemUptimeRecordRepository(source: source)
        
        try repository.launch()
        
        let descriptor = FetchDescriptor<SystemUptimeRecord>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].year == Date.now.year)
        #expect(results[0].month == Date.now.month)
        #expect(results[0].day == Date.now.day)
        #expect(results[0].launch.equals(.now))
        #expect(results[0].shutdown.equals(.now))
        #expect(results[0].sleepRecords.count == 0)
    }
    
    @Test func testLaunch_fail() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultSystemUptimeRecordRepository(source: source)
        
        try repository.launch()
        
        #expect(throws: DefaultSystemUptimeRecordRepository.SystemUptimeRecordError.alreadyRecording) {
            try repository.launch()
        }
        
        try repository.sleep()
        
        #expect(throws: DefaultSystemUptimeRecordRepository.SystemUptimeRecordError.alreadyRecording) {
            try repository.launch()
        }
    }
    
    @Test func testShutdown() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultSystemUptimeRecordRepository(source: source)
        
        try repository.launch()
        
        let descriptor = FetchDescriptor<SystemUptimeRecord>()
        guard let record = try context.fetch(descriptor).first else {
            Issue.record()
            return
        }
        record.shutdown = .distantPast
        
        try repository.shutdown()
        
        #expect(record.shutdown.equals(.now))
        
        try repository.launch()
        
        let results = try context.fetch(descriptor)
        #expect(results.count == 2)
    }
    
    @Test func testShutdown_inSleep() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultSystemUptimeRecordRepository(source: source)
        
        try repository.launch()
        try repository.sleep()
        
        let descriptor = FetchDescriptor<SystemUptimeRecord>()
        guard let record = try context.fetch(descriptor).first else {
            Issue.record()
            return
        }
        record.shutdown = .distantPast
        record.sleepRecords[0].end = .distantPast
        
        try repository.shutdown()
        
        #expect(record.shutdown.equals(.now))
        #expect(record.sleepRecords[0].end.equals(.now))
    }
    
    @Test func testShutdown_fail() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultSystemUptimeRecordRepository(source: source)
        
        #expect(throws: DefaultSystemUptimeRecordRepository.SystemUptimeRecordError.notRecording) {
            try repository.shutdown()
        }
        
        try repository.launch()
        try repository.shutdown()
        
        #expect(throws: DefaultSystemUptimeRecordRepository.SystemUptimeRecordError.notRecording) {
            try repository.shutdown()
        }
    }
    
    @Test func testSleep() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultSystemUptimeRecordRepository(source: source)
        
        try repository.launch()
        try repository.sleep()
        
        let descriptor = FetchDescriptor<SystemUptimeRecord>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].sleepRecords.count == 1)
        #expect(results[0].sleepRecords[0].start.equals(.now))
        #expect(results[0].sleepRecords[0].end.equals(.now))
    }
    
    @Test func testSleep_fail() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultSystemUptimeRecordRepository(source: source)
        
        #expect(throws: DefaultSystemUptimeRecordRepository.SystemUptimeRecordError.self) {
            try repository.sleep()
        }
        
        try repository.launch()
        try repository.sleep()
        
        #expect(throws: DefaultSystemUptimeRecordRepository.SystemUptimeRecordError.alreadySleeping) {
            try repository.sleep()
        }
    }
    
    @Test func testWake() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultSystemUptimeRecordRepository(source: source)
        
        try repository.launch()
        try repository.sleep()
        
        let descriptor = FetchDescriptor<SystemUptimeRecord>()
        guard let record = try context.fetch(descriptor).first else {
            Issue.record()
            return
        }
        record.sleepRecords[0].end = .distantPast
        
        try repository.wake()
        
        #expect(record.sleepRecords[0].end.equals(.now))
        
        try repository.sleep()
        
        #expect(record.sleepRecords.count == 2)
    }
    
    @Test func testWake_fail() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultSystemUptimeRecordRepository(source: source)
        
        #expect(throws: DefaultSystemUptimeRecordRepository.SystemUptimeRecordError.notRecording) {
            try repository.wake()
        }
        
        try repository.launch()
        
        #expect(throws: DefaultSystemUptimeRecordRepository.SystemUptimeRecordError.notSleeping) {
            try repository.wake()
        }
        
        try repository.sleep()
        try repository.wake()
        
        #expect(throws: DefaultSystemUptimeRecordRepository.SystemUptimeRecordError.notSleeping) {
            try repository.wake()
        }
    }
    
    @Test func testUpdate() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultSystemUptimeRecordRepository(source: source)
        
        try repository.launch()
        
        let descriptor = FetchDescriptor<SystemUptimeRecord>()
        guard let record = try context.fetch(descriptor).first else {
            Issue.record()
            return
        }
        record.shutdown = .distantPast
        
        try repository.update()
        
        #expect(record.shutdown.equals(.now))
    }
    
    @Test func testUpdate_inSleep() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultSystemUptimeRecordRepository(source: source)
        
        try repository.launch()
        try repository.sleep()
        
        let descriptor = FetchDescriptor<SystemUptimeRecord>()
        guard let record = try context.fetch(descriptor).first else {
            Issue.record()
            return
        }
        record.shutdown = .distantPast
        record.sleepRecords[0].end = .distantPast
        
        try repository.update()
        
        #expect(record.shutdown.equals(.now))
        #expect(record.sleepRecords[0].end.equals(.now))
    }
    
    @Test func testUpdate_dateChanged() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultSystemUptimeRecordRepository(source: source)
        
        try repository.launch()
        
        let descriptor = FetchDescriptor<SystemUptimeRecord>(
            sortBy: [.init(\.day)]
        )
        guard let record = try context.fetch(descriptor).first else {
            Issue.record()
            return
        }
        record.shutdown = .distantPast
        record.day -= 1
        
        try repository.update()
        
        let results = try context.fetch(descriptor)
        #expect(results.count == 2)
        #expect(results[0].day == Date.now.day - 1)
        #expect(results[0].shutdown.equals(.now))
        #expect(results[1].year == Date.now.year)
        #expect(results[1].month == Date.now.month)
        #expect(results[1].day == Date.now.day)
        #expect(results[1].launch.equals(.now))
        #expect(results[1].shutdown.equals(.now))
        #expect(results[1].sleepRecords.count == 0)
    }
    
    @Test func testUpdate_dateChanged_InSleep() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultSystemUptimeRecordRepository(source: source)
        
        try repository.launch()
        try repository.sleep()
        
        let descriptor = FetchDescriptor<SystemUptimeRecord>(
            sortBy: [.init(\.day)]
        )
        guard let record = try context.fetch(descriptor).first else {
            Issue.record()
            return
        }
        record.shutdown = .distantPast
        record.sleepRecords[0].end = .distantPast
        record.day -= 1
        
        try repository.update()
        
        let results = try context.fetch(descriptor)
        #expect(results.count == 2)
        #expect(results[0].day == Date.now.day - 1)
        #expect(results[0].shutdown.equals(.now))
        #expect(results[0].sleepRecords[0].end.equals(.now))
        #expect(results[1].year == Date.now.year)
        #expect(results[1].month == Date.now.month)
        #expect(results[1].day == Date.now.day)
        #expect(results[1].launch.equals(.now))
        #expect(results[1].shutdown.equals(.now))
        #expect(results[1].sleepRecords.count == 1)
        #expect(results[1].sleepRecords[0].start.equals(.now))
        #expect(results[1].sleepRecords[0].end.equals(.now))
    }
    
    @Test func testUpdate_fail() async throws {
        let source = DefaultLocalDataSource(context: context)
        let repository = DefaultSystemUptimeRecordRepository(source: source)
        
        #expect(throws: DefaultSystemUptimeRecordRepository.SystemUptimeRecordError.notRecording) {
            try repository.update()
        }
    }
}

private extension Date {
    func equals(_ date: Date) -> Bool {
        abs(self.distance(to: date)) < 1
    }
}
