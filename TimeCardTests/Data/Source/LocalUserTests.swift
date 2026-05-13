//
//  LocalUserTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2026/04/28.
//

import Foundation
import SwiftData
import Testing

@testable import TimeCard

@Suite(.serialized)
class LocalUserTests {
    
    private let urlV1: URL = FileManager.default.temporaryDirectory.appendingPathComponent("test_v1.store")
    private let urlV2_3: URL = FileManager.default.temporaryDirectory.appendingPathComponent("test_v2_3.store")
    private let urlV3: URL = FileManager.default.temporaryDirectory.appendingPathComponent("test_v3.store")
    
    deinit {
        try? FileManager.default.removeItem(at: urlV1)
        try? FileManager.default.removeItem(at: urlV1.deletingPathExtension().appendingPathExtension("store-shm"))
        try? FileManager.default.removeItem(at: urlV1.deletingPathExtension().appendingPathExtension("store-wal"))
        
        try? FileManager.default.removeItem(at: urlV2_3)
        try? FileManager.default.removeItem(at: urlV2_3.deletingPathExtension().appendingPathExtension("store-shm"))
        try? FileManager.default.removeItem(at: urlV2_3.deletingPathExtension().appendingPathExtension("store-wal"))
        
        try? FileManager.default.removeItem(at: urlV3)
        try? FileManager.default.removeItem(at: urlV3.deletingPathExtension().appendingPathExtension("store-shm"))
        try? FileManager.default.removeItem(at: urlV3.deletingPathExtension().appendingPathExtension("store-wal"))
    }
    
    @Test func testMigrateV1toV4() async throws {
        var schema = Schema([LocalTimeRecord.self, TimeCardSchema_v1.SystemUptimeRecord.self])
        var config = ModelConfiguration(schema: schema, url: urlV1)
        var container = try ModelContainer(for: schema, configurations: [config])
        var context = ModelContext(container)
        
        let timeRecords = [
            TimeCardSchema_v1.TimeRecord(year: 2026, month: 3),
            TimeCardSchema_v1.TimeRecord(year: 2026, month: 4),
        ]
        let uptimeRecords = [
            TimeCardSchema_v1.SystemUptimeRecord(year: 2026, month: 4, day: 28),
            TimeCardSchema_v1.SystemUptimeRecord(year: 2026, month: 4, day: 29)
        ]
        context.insert(timeRecords[0])
        context.insert(timeRecords[1])
        context.insert(uptimeRecords[0])
        context.insert(uptimeRecords[1])
        try context.save()
        
        schema = Schema(versionedSchema: TimeCardSchema_v4.self)
        config = ModelConfiguration(schema: schema, url: urlV1)
        container = try ModelContainer(for: schema, migrationPlan: TimeCardMigrationPlan.self, configurations: [config])
        context = ModelContext(container)
        
        let times = try context.fetch(FetchDescriptor<LocalTimeRecord>(
            sortBy: [.init(\.month)]
        ))
        #expect(times.count == 2)
        #expect(times[0].id == timeRecords[0].id)
        #expect(times[1].id == timeRecords[1].id)
        
        let uptimes = try context.fetch(FetchDescriptor<LocalUptimeRecord>(
            sortBy: [.init(\.day)]
        ))
        #expect(uptimes.count == 2)
        #expect(uptimes[0].year == uptimeRecords[0].year)
        #expect(uptimes[0].month == uptimeRecords[0].month)
        #expect(uptimes[0].day == uptimeRecords[0].day)
        #expect(uptimes[1].year == uptimeRecords[1].year)
        #expect(uptimes[1].month == uptimeRecords[1].month)
        #expect(uptimes[1].day == uptimeRecords[1].day)
        
        let users = [
            LocalUser(
                mail: "aaa@test.com",
                password: "aaa",
                verifyCode: "111",
                verifyCodeExpires: .now,
                verifyAttempts: 1,
                loginAttempts: 2,
                lastAttempt: .now,
                locked: .now,
                refreshTokens: [
                    LocalUser.RefreshToken(
                        token: "aaaaa",
                        status: .valid,
                        expire: .now
                    ),
                    LocalUser.RefreshToken(
                        token: "bbbbb",
                        status: .used,
                        expire: .now
                    )
                ]
            ),
            LocalUser(
                mail: "bbb@test.com",
                password: "bbb",
                verifyCode: "222",
                verifyCodeExpires: .now,
                verifyAttempts: 2,
                loginAttempts: 3,
                lastAttempt: nil,
                locked: nil,
                refreshTokens: []
            )
        ]
        context.insert(users[0])
        context.insert(users[1])
        try context.save()
        
        let results = try context.fetch(FetchDescriptor<LocalUser>(
            sortBy: [.init(\.mail)]
        ))
        #expect(results.count == 2)
        #expect(results[0].id == users[0].id)
        #expect(results[0].mail == users[0].mail)
        #expect(results[0].password == users[0].password)
        #expect(results[0].verifyCode == users[0].verifyCode)
        #expect(results[0].verifyCodeExpires == users[0].verifyCodeExpires)
        #expect(results[0].verifyAttempts == users[0].verifyAttempts)
        #expect(results[0].loginAttempts == users[0].loginAttempts)
        #expect(results[0].lastAttempt == users[0].lastAttempt)
        #expect(results[0].locked == users[0].locked)
        #expect(results[0].refreshTokens.count == users[0].refreshTokens.count)
        #expect(results[0].refreshTokens[0].token == users[0].refreshTokens[0].token)
        #expect(results[0].refreshTokens[0].expire == users[0].refreshTokens[0].expire)
        #expect(results[0].refreshTokens[1].token == users[0].refreshTokens[1].token)
        #expect(results[0].refreshTokens[1].expire == users[0].refreshTokens[1].expire)
        
        #expect(results[1].id == users[1].id)
        #expect(results[1].mail == users[1].mail)
        #expect(results[1].password == users[1].password)
        #expect(results[1].verifyCode == users[1].verifyCode)
        #expect(results[1].verifyCodeExpires == users[1].verifyCodeExpires)
        #expect(results[1].verifyAttempts == users[1].verifyAttempts)
        #expect(results[1].loginAttempts == users[1].loginAttempts)
        #expect(results[1].lastAttempt == users[1].lastAttempt)
        #expect(results[1].locked == users[1].locked)
        #expect(results[1].refreshTokens.count == users[1].refreshTokens.count)
    }
    
    @Test func testMigratev2_3toV4() async throws {
        var schema = Schema(versionedSchema: TimeCardSchema_v2_3.self)
        var config = ModelConfiguration(schema: schema, url: urlV2_3)
        var container = try ModelContainer(for: schema, configurations: [config])
        var context = ModelContext(container)
        
        let timeRecords = [
            TimeCardSchema_v1.TimeRecord(year: 2026, month: 3),
            TimeCardSchema_v1.TimeRecord(year: 2026, month: 4),
        ]
        let uptimeRecords = [
            TimeCardSchema_v2_3.SystemUptimeRecord_v2_3(year: 2026, month: 4, day: 28, launch: .now, shutdown: .now),
            TimeCardSchema_v2_3.SystemUptimeRecord_v2_3(year: 2026, month: 4, day: 29, launch: .now, shutdown: .now)
        ]
        context.insert(timeRecords[0])
        context.insert(timeRecords[1])
        context.insert(uptimeRecords[0])
        context.insert(uptimeRecords[1])
        try context.save()
        
        schema = Schema(versionedSchema: TimeCardSchema_v4.self)
        config = ModelConfiguration(schema: schema, url: urlV2_3)
        container = try ModelContainer(for: schema, migrationPlan: TimeCardMigrationPlan.self, configurations: [config])
        context = ModelContext(container)
        
        let times = try context.fetch(FetchDescriptor<LocalTimeRecord>(
            sortBy: [.init(\.month)]
        ))
        #expect(times.count == 2)
        #expect(times[0].id == timeRecords[0].id)
        #expect(times[1].id == timeRecords[1].id)
        
        let uptimes = try context.fetch(FetchDescriptor<LocalUptimeRecord>(
            sortBy: [.init(\.day)]
        ))
        #expect(uptimes.count == 2)
        #expect(uptimes[0].year == uptimeRecords[0].year)
        #expect(uptimes[0].month == uptimeRecords[0].month)
        #expect(uptimes[0].day == uptimeRecords[0].day)
        #expect(uptimes[0].launch == uptimeRecords[0].launch)
        #expect(uptimes[0].shutdown == uptimeRecords[0].shutdown)
        #expect(uptimes[1].year == uptimeRecords[1].year)
        #expect(uptimes[1].month == uptimeRecords[1].month)
        #expect(uptimes[1].day == uptimeRecords[1].day)
        #expect(uptimes[1].launch == uptimeRecords[1].launch)
        #expect(uptimes[1].shutdown == uptimeRecords[1].shutdown)
        
        let users = [
            LocalUser(
                mail: "aaa@test.com",
                password: "aaa",
                verifyCode: "111",
                verifyCodeExpires: .now,
                verifyAttempts: 1,
                loginAttempts: 2,
                lastAttempt: .now,
                locked: .now,
                refreshTokens: [
                    LocalUser.RefreshToken(
                        token: "aaaaa",
                        status: .valid,
                        expire: .now
                    ),
                    LocalUser.RefreshToken(
                        token: "bbbbb",
                        status: .used,
                        expire: .now
                    )
                ]
            ),
            LocalUser(
                mail: "bbb@test.com",
                password: "bbb",
                verifyCode: "222",
                verifyCodeExpires: .now,
                verifyAttempts: 2,
                loginAttempts: 3,
                lastAttempt: nil,
                locked: nil,
                refreshTokens: []
            )
        ]
        context.insert(users[0])
        context.insert(users[1])
        try context.save()
        
        let results = try context.fetch(FetchDescriptor<LocalUser>(
            sortBy: [.init(\.mail)]
        ))
        #expect(results.count == 2)
        #expect(results[0].id == users[0].id)
        #expect(results[0].mail == users[0].mail)
        #expect(results[0].password == users[0].password)
        #expect(results[0].verifyCode == users[0].verifyCode)
        #expect(results[0].verifyCodeExpires == users[0].verifyCodeExpires)
        #expect(results[0].verifyAttempts == users[0].verifyAttempts)
        #expect(results[0].loginAttempts == users[0].loginAttempts)
        #expect(results[0].lastAttempt == users[0].lastAttempt)
        #expect(results[0].locked == users[0].locked)
        #expect(results[0].refreshTokens.count == users[0].refreshTokens.count)
        #expect(results[0].refreshTokens[0].token == users[0].refreshTokens[0].token)
        #expect(results[0].refreshTokens[0].expire == users[0].refreshTokens[0].expire)
        #expect(results[0].refreshTokens[1].token == users[0].refreshTokens[1].token)
        #expect(results[0].refreshTokens[1].expire == users[0].refreshTokens[1].expire)
        
        #expect(results[1].id == users[1].id)
        #expect(results[1].mail == users[1].mail)
        #expect(results[1].password == users[1].password)
        #expect(results[1].verifyCode == users[1].verifyCode)
        #expect(results[1].verifyCodeExpires == users[1].verifyCodeExpires)
        #expect(results[1].verifyAttempts == users[1].verifyAttempts)
        #expect(results[1].loginAttempts == users[1].loginAttempts)
        #expect(results[1].lastAttempt == users[1].lastAttempt)
        #expect(results[1].locked == users[1].locked)
        #expect(results[1].refreshTokens.count == users[1].refreshTokens.count)
    }
    
    @Test func testMigratev3toV4() async throws {
        var schema = Schema(versionedSchema: TimeCardSchema_v3.self)
        var config = ModelConfiguration(schema: schema, url: urlV3)
        var container = try ModelContainer(for: schema, configurations: [config])
        var context = ModelContext(container)
        
        let timeRecords = [
            TimeCardSchema_v1.TimeRecord(year: 2026, month: 3),
            TimeCardSchema_v1.TimeRecord(year: 2026, month: 4),
        ]
        let uptimeRecords = [
            TimeCardSchema_v3.SystemUptimeRecord_v3(year: 2026, month: 4, day: 28, launch: .now, shutdown: .now),
            TimeCardSchema_v3.SystemUptimeRecord_v3(year: 2026, month: 4, day: 29, launch: .now, shutdown: .now)
        ]
        context.insert(timeRecords[0])
        context.insert(timeRecords[1])
        context.insert(uptimeRecords[0])
        context.insert(uptimeRecords[1])
        try context.save()
        
        schema = Schema(versionedSchema: TimeCardSchema_v4.self)
        config = ModelConfiguration(schema: schema, url: urlV3)
        container = try ModelContainer(for: schema, migrationPlan: TimeCardMigrationPlan.self, configurations: [config])
        context = ModelContext(container)
        
        let times = try context.fetch(FetchDescriptor<LocalTimeRecord>(
            sortBy: [.init(\.month)]
        ))
        #expect(times.count == 2)
        #expect(times[0].id == timeRecords[0].id)
        #expect(times[1].id == timeRecords[1].id)
        
        let uptimes = try context.fetch(FetchDescriptor<LocalUptimeRecord>(
            sortBy: [.init(\.day)]
        ))
        #expect(uptimes.count == 2)
        #expect(uptimes[0].id == uptimeRecords[0].id)
        #expect(uptimes[1].id == uptimeRecords[1].id)
        
        let users = [
            LocalUser(
                mail: "aaa@test.com",
                password: "aaa",
                verifyCode: "111",
                verifyCodeExpires: .now,
                verifyAttempts: 1,
                loginAttempts: 2,
                lastAttempt: .now,
                locked: .now,
                refreshTokens: [
                    LocalUser.RefreshToken(
                        token: "aaaaa",
                        status: .valid,
                        expire: .now
                    ),
                    LocalUser.RefreshToken(
                        token: "bbbbb",
                        status: .used,
                        expire: .now
                    )
                ]
            ),
            LocalUser(
                mail: "bbb@test.com",
                password: "bbb",
                verifyCode: "222",
                verifyCodeExpires: .now,
                verifyAttempts: 2,
                loginAttempts: 3,
                lastAttempt: nil,
                locked: nil,
                refreshTokens: []
            )
        ]
        context.insert(users[0])
        context.insert(users[1])
        try context.save()
        
        let results = try context.fetch(FetchDescriptor<LocalUser>(
            sortBy: [.init(\.mail)]
        ))
        #expect(results.count == 2)
        #expect(results[0].id == users[0].id)
        #expect(results[0].mail == users[0].mail)
        #expect(results[0].password == users[0].password)
        #expect(results[0].verifyCode == users[0].verifyCode)
        #expect(results[0].verifyCodeExpires == users[0].verifyCodeExpires)
        #expect(results[0].verifyAttempts == users[0].verifyAttempts)
        #expect(results[0].loginAttempts == users[0].loginAttempts)
        #expect(results[0].lastAttempt == users[0].lastAttempt)
        #expect(results[0].locked == users[0].locked)
        #expect(results[0].refreshTokens.count == users[0].refreshTokens.count)
        #expect(results[0].refreshTokens[0].token == users[0].refreshTokens[0].token)
        #expect(results[0].refreshTokens[0].expire == users[0].refreshTokens[0].expire)
        #expect(results[0].refreshTokens[1].token == users[0].refreshTokens[1].token)
        #expect(results[0].refreshTokens[1].expire == users[0].refreshTokens[1].expire)
        
        #expect(results[1].id == users[1].id)
        #expect(results[1].mail == users[1].mail)
        #expect(results[1].password == users[1].password)
        #expect(results[1].verifyCode == users[1].verifyCode)
        #expect(results[1].verifyCodeExpires == users[1].verifyCodeExpires)
        #expect(results[1].verifyAttempts == users[1].verifyAttempts)
        #expect(results[1].loginAttempts == users[1].loginAttempts)
        #expect(results[1].lastAttempt == users[1].lastAttempt)
        #expect(results[1].locked == users[1].locked)
        #expect(results[1].refreshTokens.count == users[1].refreshTokens.count)
    }
}
