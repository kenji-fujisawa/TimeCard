//
//  SystemUptimeRecordTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2025/11/13.
//

import Foundation
import SwiftData
import Testing

@testable import TimeCard

class SystemUptimeRecordTests {
    
    private let url: URL = FileManager.default.temporaryDirectory.appendingPathComponent("test.store")
    
    deinit {
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("store-shm"))
        try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("store-wal"))
    }
    
    @Test func testUptimes() async throws {
        let launch1 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 9, minute: 0, second: 0))
        let shutdown1 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 18, minute: 0, second: 0))
        let sleepStart1_1 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 12, minute: 0, second: 0))
        let sleepEnd1_1 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 13, minute: 0, second: 0))
        let sleepStart1_2 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 15, minute: 0, second: 0))
        let sleepEnd1_2 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 15, minute: 30, second: 0))
        let sleepStart1_3 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 17, minute: 0, second: 0))
        let sleepEnd1_3 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 17, minute: 0, second: 30))
        
        let record = SystemUptimeRecord(year: 2025, month: 11, day: 13, launch: launch1!, shutdown: shutdown1!)
        let hour9: TimeInterval = 9 * 60 * 60
        #expect(record.uptimes == hour9)
        
        let sleep1 = SystemUptimeRecord.SleepRecord(start: sleepStart1_1!, end: sleepEnd1_1!)
        record.sleepRecords.append(sleep1)
        let hour8: TimeInterval = 8 * 60 * 60
        #expect(record.uptimes == hour8)
        
        let sleep2 = SystemUptimeRecord.SleepRecord(start: sleepStart1_2!, end: sleepEnd1_2!)
        record.sleepRecords.append(sleep2)
        let hour7_5: TimeInterval = hour8 - 30 * 60
        #expect(record.uptimes == hour7_5)
        
        let sleep3 = SystemUptimeRecord.SleepRecord(start: sleepStart1_3!, end: sleepEnd1_3!)
        record.sleepRecords.append(sleep3)
        #expect(record.uptimes == hour7_5 - 30)
    }
    
    @Test func testMigrateV1toV2_3() async throws {
        var schema = Schema([TimeRecord.self, TimeCardSchema_v1.SystemUptimeRecord.self])
        var config = ModelConfiguration(schema: schema, url: url)
        var container = try ModelContainer(for: schema, configurations: [config])
        var context = ModelContext(container)
        
        let sleep1_1 = TimeCardSchema_v1.SystemUptimeRecord.SleepRecord(start: 60, end: 120)
        let sleep1_2 = TimeCardSchema_v1.SystemUptimeRecord.SleepRecord(start: 180, end: 210)
        let record1 = TimeCardSchema_v1.SystemUptimeRecord(year: 2025, month: 12, day: 5, launch: 0, shutdown: 300, sleepRecords: [sleep1_1, sleep1_2])
        let record2 = TimeCardSchema_v1.SystemUptimeRecord(year: 2025, month: 12, day: 10, launch: 60, shutdown: 300, sleepRecords: [])
        context.insert(record1)
        context.insert(record2)
        try context.save()
        
        let descriptorV1 = FetchDescriptor<TimeCardSchema_v1.SystemUptimeRecord>(
            sortBy: [.init(\.day)]
        )
        let recordsV1 = try context.fetch(descriptorV1)
        #expect(recordsV1.count == 2)
        #expect(recordsV1[0].sleepRecords.count == 2)
        #expect(recordsV1[1].sleepRecords.count == 0)
        
        schema = Schema(versionedSchema: TimeCardSchema_v2_3.self)
        config = ModelConfiguration(schema: schema, url: url)
        container = try ModelContainer(for: schema, migrationPlan: TimeCardMigrationPlan.self, configurations: [config])
        context = ModelContext(container)
        
        let descriptor = FetchDescriptor<TimeCardSchema_v2_3.SystemUptimeRecord_v2_3>(
            sortBy: [.init(\.day)]
        )
        let records = try context.fetch(descriptor)
        
        let get = { (date: Date, component: Calendar.Component) in            Calendar.current.component(component, from: date)
        }
        
        #expect(records.count == 2)
        #expect(records[0].year == 2025)
        #expect(records[0].month == 12)
        #expect(records[0].day == 5)
        #expect(get(records[0].launch, .year) == 2025)
        #expect(get(records[0].launch, .month) == 12)
        #expect(get(records[0].launch, .day) == 5)
        #expect(get(records[0].launch, .hour) == 0)
        #expect(get(records[0].launch, .minute) == 0)
        #expect(get(records[0].launch, .second) == 0)
        #expect(get(records[0].shutdown, .year) == 2025)
        #expect(get(records[0].shutdown, .month) == 12)
        #expect(get(records[0].shutdown, .day) == 5)
        #expect(get(records[0].shutdown, .hour) == 0)
        #expect(get(records[0].shutdown, .minute) == 5)
        #expect(get(records[0].shutdown, .second) == 0)
        
        #expect(records[0].sleepRecords.count == 2)
        #expect(get(records[0].sortedSleepRecords[0].start, .year) == 2025)
        #expect(get(records[0].sortedSleepRecords[0].start, .month) == 12)
        #expect(get(records[0].sortedSleepRecords[0].start, .day) == 5)
        #expect(get(records[0].sortedSleepRecords[0].start, .hour) == 0)
        #expect(get(records[0].sortedSleepRecords[0].start, .minute) == 1)
        #expect(get(records[0].sortedSleepRecords[0].start, .second) == 0)
        #expect(get(records[0].sortedSleepRecords[0].end, .year) == 2025)
        #expect(get(records[0].sortedSleepRecords[0].end, .month) == 12)
        #expect(get(records[0].sortedSleepRecords[0].end, .day) == 5)
        #expect(get(records[0].sortedSleepRecords[0].end, .hour) == 0)
        #expect(get(records[0].sortedSleepRecords[0].end, .minute) == 2)
        #expect(get(records[0].sortedSleepRecords[0].end, .second) == 0)
        
        #expect(get(records[0].sortedSleepRecords[1].start, .year) == 2025)
        #expect(get(records[0].sortedSleepRecords[1].start, .month) == 12)
        #expect(get(records[0].sortedSleepRecords[1].start, .day) == 5)
        #expect(get(records[0].sortedSleepRecords[1].start, .hour) == 0)
        #expect(get(records[0].sortedSleepRecords[1].start, .minute) == 3)
        #expect(get(records[0].sortedSleepRecords[1].start, .second) == 0)
        #expect(get(records[0].sortedSleepRecords[1].end, .year) == 2025)
        #expect(get(records[0].sortedSleepRecords[1].end, .month) == 12)
        #expect(get(records[0].sortedSleepRecords[1].end, .day) == 5)
        #expect(get(records[0].sortedSleepRecords[1].end, .hour) == 0)
        #expect(get(records[0].sortedSleepRecords[1].end, .minute) == 3)
        #expect(get(records[0].sortedSleepRecords[1].end, .second) == 30)
        
        #expect(records[1].year == 2025)
        #expect(records[1].month == 12)
        #expect(records[1].day == 10)
        #expect(get(records[1].launch, .year) == 2025)
        #expect(get(records[1].launch, .month) == 12)
        #expect(get(records[1].launch, .day) == 10)
        #expect(get(records[1].launch, .hour) == 0)
        #expect(get(records[1].launch, .minute) == 1)
        #expect(get(records[1].launch, .second) == 0)
        #expect(get(records[1].shutdown, .year) == 2025)
        #expect(get(records[1].shutdown, .month) == 12)
        #expect(get(records[1].shutdown, .day) == 10)
        #expect(get(records[1].shutdown, .hour) == 0)
        #expect(get(records[1].shutdown, .minute) == 5)
        #expect(get(records[1].shutdown, .second) == 0)
        
        #expect(records[1].sleepRecords.count == 0)
    }

}
