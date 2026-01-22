//
//  TimeCardSchema.swift
//  TimeCard
//
//  Created by uhimania on 2025/12/08.
//

import Foundation
import SwiftData

struct TimeCardSchema_v1: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] = [
        TimeCardSchema_v1.TimeRecord.self,
        TimeCardSchema_v1.TimeRecord.BreakTime.self,
        TimeCardSchema_v1.SystemUptimeRecord.self,
        TimeCardSchema_v1.SystemUptimeRecord.SleepRecord.self
    ]
}

struct TimeCardSchema_v2_3: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(2, 3, 0)
    static var models: [any PersistentModel.Type] = [
        TimeCardSchema_v1.TimeRecord.self,
        TimeCardSchema_v1.TimeRecord.BreakTime.self,
        TimeCardSchema_v2_3.SystemUptimeRecord_v2_3.self,
        TimeCardSchema_v2_3.SystemUptimeRecord_v2_3.SleepRecord_v2_3.self
    ]
}

struct TimeCardSchema_v3: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] = [
        TimeCardSchema_v1.TimeRecord.self,
        TimeCardSchema_v1.TimeRecord.BreakTime.self,
        TimeCardSchema_v3.SystemUptimeRecord_v3.self,
        TimeCardSchema_v3.SystemUptimeRecord_v3.SleepRecord_v3.self
    ]
}

enum TimeCardMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        TimeCardSchema_v1.self,
        TimeCardSchema_v2_3.self,
        TimeCardSchema_v3.self
    ]
    
    static var stages: [MigrationStage] = [
        migrateV1toV2_3,
        migrateV2_3toV3
    ]
    
    private static var records_v2_3: [TimeCardSchema_v2_3.SystemUptimeRecord_v2_3] = []
    private static var records_v3: [TimeCardSchema_v3.SystemUptimeRecord_v3] = []
    
    static let migrateV1toV2_3 = MigrationStage.custom(
        fromVersion: TimeCardSchema_v1.self,
        toVersion: TimeCardSchema_v2_3.self,
        willMigrate: { context in
            let oldRecords = try context.fetch(FetchDescriptor<TimeCardSchema_v1.SystemUptimeRecord>())
            
            records_v2_3 = oldRecords.map({ rec in
                guard let baseDate = Calendar.current.date(from: DateComponents(year: rec.year, month: rec.month, day: rec.day)) else {
                    fatalError()
                }
                
                let sleepRecords = rec.sleepRecords.map { sleep in
                    TimeCardSchema_v2_3.SystemUptimeRecord_v2_3.SleepRecord_v2_3(
                        start: Date(timeInterval: sleep.start, since: baseDate),
                        end: Date(timeInterval: sleep.end, since: baseDate)
                    )
                }
                
                return TimeCardSchema_v2_3.SystemUptimeRecord_v2_3(
                    year: rec.year,
                    month: rec.month,
                    day: rec.day,
                    launch: Date(timeInterval: rec.launch, since: baseDate),
                    shutdown: Date(timeInterval: rec.shutdown, since: baseDate),
                    sleepRecords: sleepRecords
                )
            })
        },
        didMigrate: { context in
            for record in records_v2_3 {
                context.insert(record)
            }
            try context.save()
        }
    )
    
    static let migrateV2_3toV3 = MigrationStage.custom(
        fromVersion: TimeCardSchema_v2_3.self,
        toVersion: TimeCardSchema_v3.self,
        willMigrate: { context in
            let oldRecords = try context.fetch(FetchDescriptor<TimeCardSchema_v2_3.SystemUptimeRecord_v2_3>())
            
            records_v3 = oldRecords.map({ rec in
                let sleepRecords = rec.sleepRecords.map { sleep in
                    TimeCardSchema_v3.SystemUptimeRecord_v3.SleepRecord_v3(
                        id: UUID(),
                        start: sleep.start,
                        end: sleep.end
                    )
                }
                
                return TimeCardSchema_v3.SystemUptimeRecord_v3(
                    id: UUID(),
                    year: rec.year,
                    month: rec.month,
                    day: rec.day,
                    launch: rec.launch,
                    shutdown: rec.shutdown,
                    sleepRecords: sleepRecords
                )
            })
        },
        didMigrate: { context in
            for record in records_v3 {
                context.insert(record)
            }
            try context.save()
        }
    )
}
