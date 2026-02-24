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
    
    private let urlV1: URL = FileManager.default.temporaryDirectory.appendingPathComponent("test_v1.store")
    private let urlV2_3: URL = FileManager.default.temporaryDirectory.appendingPathComponent("test_v2_3.store")
    
    deinit {
        try? FileManager.default.removeItem(at: urlV1)
        try? FileManager.default.removeItem(at: urlV1.deletingPathExtension().appendingPathExtension("store-shm"))
        try? FileManager.default.removeItem(at: urlV1.deletingPathExtension().appendingPathExtension("store-wal"))
        
        try? FileManager.default.removeItem(at: urlV2_3)
        try? FileManager.default.removeItem(at: urlV2_3.deletingPathExtension().appendingPathExtension("store-shm"))
        try? FileManager.default.removeItem(at: urlV2_3.deletingPathExtension().appendingPathExtension("store-wal"))
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
    
    @Test func testMigrateV1toV3() async throws {
        var schema = Schema([TimeRecord.self, TimeCardSchema_v1.SystemUptimeRecord.self])
        var config = ModelConfiguration(schema: schema, url: urlV1)
        var container = try ModelContainer(for: schema, configurations: [config])
        var context = ModelContext(container)
        
        let recs = [
            TimeCardSchema_v1.SystemUptimeRecord(
                year: 2025,
                month: 12,
                day: 5,
                launch: 0,
                shutdown: 300,
                sleepRecords: [
                    TimeCardSchema_v1.SystemUptimeRecord.SleepRecord(
                        start: 60,
                        end: 120
                    ),
                    TimeCardSchema_v1.SystemUptimeRecord.SleepRecord(
                        start: 180,
                        end: 210
                    )
                ]
            ),
            TimeCardSchema_v1.SystemUptimeRecord(
                year: 2025,
                month: 12,
                day: 10,
                launch: 60,
                shutdown: 300,
                sleepRecords: []
            )
        ]
        context.insert(recs[0])
        context.insert(recs[1])
        try context.save()
        
        let descriptorV1 = FetchDescriptor<TimeCardSchema_v1.SystemUptimeRecord>(
            sortBy: [.init(\.day)]
        )
        let recordsV1 = try context.fetch(descriptorV1)
        #expect(recordsV1.count == 2)
        #expect(recordsV1[0].sleepRecords.count == 2)
        #expect(recordsV1[1].sleepRecords.count == 0)
        
        schema = Schema(versionedSchema: TimeCardSchema_v3.self)
        config = ModelConfiguration(schema: schema, url: urlV1)
        container = try ModelContainer(for: schema, migrationPlan: TimeCardMigrationPlan.self, configurations: [config])
        context = ModelContext(container)
        
        let descriptor = FetchDescriptor<TimeCardSchema_v3.SystemUptimeRecord_v3>(
            sortBy: [.init(\.day)]
        )
        let records = try context.fetch(descriptor)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        #expect(records.count == 2)
        #expect(records[0].year == 2025)
        #expect(records[0].month == 12)
        #expect(records[0].day == 5)
        #expect(records[0].launch == formatter.date(from: "2025-12-05 00:00:00"))
        #expect(records[0].shutdown == formatter.date(from: "2025-12-05 00:05:00"))
        
        #expect(records[0].sleepRecords.count == 2)
        #expect(records[0].sortedSleepRecords[0].start == formatter.date(from: "2025-12-05 00:01:00"))
        #expect(records[0].sortedSleepRecords[0].end == formatter.date(from: "2025-12-05 00:02:00"))
        #expect(records[0].sortedSleepRecords[1].start == formatter.date(from: "2025-12-05 00:03:00"))
        #expect(records[0].sortedSleepRecords[1].end == formatter.date(from: "2025-12-05 00:03:30"))
        
        #expect(records[1].year == 2025)
        #expect(records[1].month == 12)
        #expect(records[1].day == 10)
        #expect(records[1].launch == formatter.date(from: "2025-12-10 00:01:00"))
        #expect(records[1].shutdown == formatter.date(from: "2025-12-10 00:05:00"))
        
        #expect(records[1].sleepRecords.count == 0)
    }
    
    @Test func testMigrateV2_3toV3() async throws {
        var schema = Schema(versionedSchema: TimeCardSchema_v2_3.self)
        var config = ModelConfiguration(schema: schema, url: urlV2_3)
        var container = try ModelContainer(for: schema, configurations: [config])
        var context = ModelContext(container)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let recs = [
            TimeCardSchema_v2_3.SystemUptimeRecord_v2_3(
                year: 2026,
                month: 1,
                day: 16,
                launch: formatter.date(from: "2026-01-16 08:00:00") ?? .now,
                shutdown: formatter.date(from: "2026-01-16 19:00:00") ?? .now,
                sleepRecords: [
                    TimeCardSchema_v2_3.SystemUptimeRecord_v2_3.SleepRecord_v2_3(
                        start: formatter.date(from: "2026-01-16 12:00:00") ?? .now,
                        end: formatter.date(from: "2026-01-16 13:00:00") ?? .now
                    ),
                    TimeCardSchema_v2_3.SystemUptimeRecord_v2_3.SleepRecord_v2_3(
                        start: formatter.date(from: "2026-01-16 15:00:00") ?? .now,
                        end: formatter.date(from: "2026-01-16 15:30:00") ?? .now
                    )
                ]
            ),
            TimeCardSchema_v2_3.SystemUptimeRecord_v2_3(
                year: 2026,
                month: 1,
                day: 20,
                launch: formatter.date(from: "2026-01-20 09:00:00") ?? .now,
                shutdown: formatter.date(from: "2026-01-20 18:00:00") ?? .now,
                sleepRecords: []
            )
        ]
        context.insert(recs[0])
        context.insert(recs[1])
        try context.save()
        
        let descriptorV2_3 = FetchDescriptor<TimeCardSchema_v2_3.SystemUptimeRecord_v2_3>(
            sortBy: [.init(\.day)]
        )
        let recordsV2_3 = try context.fetch(descriptorV2_3)
        #expect(recordsV2_3.count == 2)
        #expect(recordsV2_3[0].sleepRecords.count == 2)
        #expect(recordsV2_3[1].sleepRecords.count == 0)
        
        schema = Schema(versionedSchema: TimeCardSchema_v3.self)
        config = ModelConfiguration(schema: schema, url: urlV2_3)
        container = try ModelContainer(for: schema, migrationPlan: TimeCardMigrationPlan.self, configurations: [config])
        context = ModelContext(container)
        
        let descriptor = FetchDescriptor<TimeCardSchema_v3.SystemUptimeRecord_v3>(
            sortBy: [.init(\.day)]
        )
        let records = try context.fetch(descriptor)
        
        #expect(records.count == 2)
        #expect(!records[0].id.uuidString.isEmpty)
        #expect(records[0].year == 2026)
        #expect(records[0].month == 1)
        #expect(records[0].day == 16)
        #expect(records[0].launch == formatter.date(from: "2026-01-16 08:00:00"))
        #expect(records[0].shutdown == formatter.date(from: "2026-01-16 19:00:00"))
        
        #expect(records[0].sleepRecords.count == 2)
        #expect(records[0].sortedSleepRecords[0].start == formatter.date(from: "2026-01-16 12:00:00"))
        #expect(records[0].sortedSleepRecords[0].end == formatter.date(from: "2026-01-16 13:00:00"))
        #expect(records[0].sortedSleepRecords[1].start == formatter.date(from: "2026-01-16 15:00:00"))
        #expect(records[0].sortedSleepRecords[1].end == formatter.date(from: "2026-01-16 15:30:00"))
        
        #expect(!records[1].id.uuidString.isEmpty)
        #expect(records[1].year == 2026)
        #expect(records[1].month == 1)
        #expect(records[1].day == 20)
        #expect(records[1].launch == formatter.date(from: "2026-01-20 09:00:00"))
        #expect(records[1].shutdown == formatter.date(from: "2026-01-20 18:00:00"))
        
        #expect(records[1].sleepRecords.count == 0)
    }
}
