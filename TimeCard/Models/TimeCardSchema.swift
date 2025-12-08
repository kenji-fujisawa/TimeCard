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

enum TimeCardMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        TimeCardSchema_v1.self,
        TimeCardSchema_v2_3.self
    ]
    
    static var stages: [MigrationStage] = [migrateV1toV2_3]
    
    private static var records: [TimeCardSchema_v2_3.SystemUptimeRecord_v2_3] = []
    
    static let migrateV1toV2_3 = MigrationStage.custom(
        fromVersion: TimeCardSchema_v1.self,
        toVersion: TimeCardSchema_v2_3.self,
        willMigrate: { context in
            let oldRecords = try context.fetch(FetchDescriptor<TimeCardSchema_v1.SystemUptimeRecord>())
            
            records = oldRecords.map({ rec in
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
            for record in records {
                context.insert(record)
            }
            try context.save()
        }
    )
}
