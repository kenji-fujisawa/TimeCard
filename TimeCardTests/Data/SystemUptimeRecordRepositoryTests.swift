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
        let localSource = DefaultLocalDataSource(context)
        let fileSource = FakeFileDataSource()
        let repository = DefaultSystemUptimeRecordRepository(localSource, fileSource)
        
        try repository.launch()
        
        let descriptor = FetchDescriptor<LocalUptimeRecord>()
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
        let localSource = DefaultLocalDataSource(context)
        let fileSource = FakeFileDataSource()
        let repository = DefaultSystemUptimeRecordRepository(localSource, fileSource)
        
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
        let localSource = DefaultLocalDataSource(context)
        let fileSource = FakeFileDataSource()
        let repository = DefaultSystemUptimeRecordRepository(localSource, fileSource)
        
        try repository.launch()
        
        let descriptor = FetchDescriptor<LocalUptimeRecord>()
        guard let record = try context.fetch(descriptor).first else {
            Issue.record()
            return
        }
        record.shutdown = .distantPast
        
        try repository.shutdown()
        
        #expect(record.shutdown.equals(.now))
        
        #expect(fileSource.records == [record.asUptimeRecord()])
        
        try repository.launch()
        
        let results = try context.fetch(descriptor)
        #expect(results.count == 2)
    }
    
    @Test func testShutdown_inSleep() async throws {
        let localSource = DefaultLocalDataSource(context)
        let fileSource = FakeFileDataSource()
        let repository = DefaultSystemUptimeRecordRepository(localSource, fileSource)
        
        try repository.launch()
        try repository.sleep()
        
        let descriptor = FetchDescriptor<LocalUptimeRecord>()
        guard let record = try context.fetch(descriptor).first else {
            Issue.record()
            return
        }
        record.shutdown = .distantPast
        record.sleepRecords[0].end = .distantPast
        
        try repository.shutdown()
        
        #expect(record.shutdown.equals(.now))
        #expect(record.sleepRecords[0].end.equals(.now))
        
        #expect(fileSource.records == [record.asUptimeRecord()])
    }
    
    @Test func testShutdown_fail() async throws {
        let localSource = DefaultLocalDataSource(context)
        let fileSource = FakeFileDataSource()
        let repository = DefaultSystemUptimeRecordRepository(localSource, fileSource)
        
        #expect(throws: DefaultSystemUptimeRecordRepository.SystemUptimeRecordError.notRecording) {
            try repository.shutdown()
        }
        
        #expect(fileSource.records.isEmpty)
        
        try repository.launch()
        try repository.shutdown()
        
        #expect(fileSource.records.count == 1)
        fileSource.records.removeAll()
        
        #expect(throws: DefaultSystemUptimeRecordRepository.SystemUptimeRecordError.notRecording) {
            try repository.shutdown()
        }
        
        #expect(fileSource.records.isEmpty)
    }
    
    @Test func testSleep() async throws {
        let localSource = DefaultLocalDataSource(context)
        let fileSource = FakeFileDataSource()
        let repository = DefaultSystemUptimeRecordRepository(localSource, fileSource)
        
        try repository.launch()
        try repository.sleep()
        
        let descriptor = FetchDescriptor<LocalUptimeRecord>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].sleepRecords.count == 1)
        #expect(results[0].sleepRecords[0].start.equals(.now))
        #expect(results[0].sleepRecords[0].end.equals(.now))
    }
    
    @Test func testSleep_fail() async throws {
        let localSource = DefaultLocalDataSource(context)
        let fileSource = FakeFileDataSource()
        let repository = DefaultSystemUptimeRecordRepository(localSource, fileSource)
        
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
        let localSource = DefaultLocalDataSource(context)
        let fileSource = FakeFileDataSource()
        let repository = DefaultSystemUptimeRecordRepository(localSource, fileSource)
        
        try repository.launch()
        try repository.sleep()
        
        let descriptor = FetchDescriptor<LocalUptimeRecord>()
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
        let localSource = DefaultLocalDataSource(context)
        let fileSource = FakeFileDataSource()
        let repository = DefaultSystemUptimeRecordRepository(localSource, fileSource)
        
        #expect(throws: DefaultSystemUptimeRecordRepository.SystemUptimeRecordError.notSleeping) {
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
        let localSource = DefaultLocalDataSource(context)
        let fileSource = FakeFileDataSource()
        let repository = DefaultSystemUptimeRecordRepository(localSource, fileSource)
        
        try repository.launch()
        
        let descriptor = FetchDescriptor<LocalUptimeRecord>()
        guard let record = try context.fetch(descriptor).first else {
            Issue.record()
            return
        }
        record.shutdown = .distantPast
        
        try repository.update()
        
        #expect(record.shutdown.equals(.now))
        
        #expect(fileSource.records == [record.asUptimeRecord()])
    }
    
    @Test func testUpdate_inSleep() async throws {
        let localSource = DefaultLocalDataSource(context)
        let fileSource = FakeFileDataSource()
        let repository = DefaultSystemUptimeRecordRepository(localSource, fileSource)
        
        try repository.launch()
        try repository.sleep()
        
        let descriptor = FetchDescriptor<LocalUptimeRecord>()
        guard let record = try context.fetch(descriptor).first else {
            Issue.record()
            return
        }
        record.shutdown = .distantPast
        record.sleepRecords[0].end = .distantPast
        
        try repository.update()
        
        #expect(record.shutdown.equals(.now))
        #expect(record.sleepRecords[0].end.equals(.now))
        
        #expect(fileSource.records == [record.asUptimeRecord()])
    }
    
    @Test func testUpdate_dateChanged() async throws {
        let localSource = DefaultLocalDataSource(context)
        let fileSource = FakeFileDataSource()
        let repository = DefaultSystemUptimeRecordRepository(localSource, fileSource)
        
        try repository.launch()
        
        let descriptor = FetchDescriptor<LocalUptimeRecord>(
            sortBy: [.init(\.launch)]
        )
        guard let record = try context.fetch(descriptor).first else {
            Issue.record()
            return
        }
        record.launch -= 24 * 60 * 60
        record.shutdown = .distantPast
        
        try repository.update()
        
        let results = try context.fetch(descriptor)
        #expect(results.count == 2)
        #expect(results[0].day == Date(timeIntervalSinceNow: -24 * 60 * 60).day)
        #expect(results[0].launch.day == Date(timeIntervalSinceNow: -24 * 60 * 60).day)
        #expect(results[0].shutdown.equals(.now))
        #expect(results[1].year == Date.now.year)
        #expect(results[1].month == Date.now.month)
        #expect(results[1].day == Date.now.day)
        #expect(results[1].launch.equals(.now))
        #expect(results[1].shutdown.equals(.now))
        #expect(results[1].sleepRecords.count == 0)
        
        #expect(fileSource.records == results.map { $0.asUptimeRecord() })
    }
    
    @Test func testUpdate_dateChanged_InSleep() async throws {
        let localSource = DefaultLocalDataSource(context)
        let fileSource = FakeFileDataSource()
        let repository = DefaultSystemUptimeRecordRepository(localSource, fileSource)
        
        try repository.launch()
        try repository.sleep()
        
        let descriptor = FetchDescriptor<LocalUptimeRecord>(
            sortBy: [.init(\.launch)]
        )
        guard let record = try context.fetch(descriptor).first else {
            Issue.record()
            return
        }
        record.launch -= 24 * 60 * 60
        record.shutdown = .distantPast
        record.sleepRecords[0].end = .distantPast
        
        try repository.update()
        
        let results = try context.fetch(descriptor)
        #expect(results.count == 2)
        #expect(results[0].day == Date(timeIntervalSinceNow: -24 * 60 * 60).day)
        #expect(results[0].launch.day == Date(timeIntervalSinceNow: -24 * 60 * 60).day)
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
        
        #expect(fileSource.records == results.map { $0.asUptimeRecord() })
    }
    
    @Test func testUpdate_fail() async throws {
        let localSource = DefaultLocalDataSource(context)
        let fileSource = FakeFileDataSource()
        let repository = DefaultSystemUptimeRecordRepository(localSource, fileSource)
        
        #expect(throws: DefaultSystemUptimeRecordRepository.SystemUptimeRecordError.notRecording) {
            try repository.update()
        }
        
        #expect(fileSource.records.isEmpty)
    }
    
    @Test func testRestoreBackup() async throws {
        let localSource = DefaultLocalDataSource(context)
        let fileSource = FakeFileDataSource()
        let repository = DefaultSystemUptimeRecordRepository(localSource, fileSource)
        
        var records = [SystemUptimeRecord(launch: .now, shutdown: .now)]
        fileSource.records = records
        try repository.restoreBackup()
        
        let descriptor = FetchDescriptor<LocalUptimeRecord>()
        var results = try context.fetch(descriptor)
        #expect(results.map { $0.asUptimeRecord() } == records)
        #expect(fileSource.records.isEmpty)
        
        records[0].sleepRecords.append(SystemUptimeRecord.SleepRecord(start: .now, end: .now))
        fileSource.records = records
        try repository.restoreBackup()
        
        results = try context.fetch(descriptor)
        #expect(results.map { $0.asUptimeRecord() } == records)
        #expect(fileSource.records.isEmpty)
    }
    
    class FakeFileDataSource: FileDataSource {
        var records: [SystemUptimeRecord] = []
        func getUptimeRecords() throws -> [TimeCard.SystemUptimeRecord] {
            records
        }
        
        func saveUptimeRecords(_ records: [TimeCard.SystemUptimeRecord]) throws {
            self.records = records
        }
        
        func removeUptimeRecords() throws {
            records.removeAll()
        }
    }
}

private extension Date {
    func equals(_ date: Date) -> Bool {
        abs(self.distance(to: date)) < 1
    }
}
