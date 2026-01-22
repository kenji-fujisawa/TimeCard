//
//  SystemUptimeRecord.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/15.
//

import Foundation
import SwiftData

extension TimeCardSchema_v1 {
    @Model
    class SystemUptimeRecord {
        @Model
        class SleepRecord {
            var start: TimeInterval
            var end: TimeInterval
            var parent: SystemUptimeRecord?
            
            init(start: TimeInterval, end: TimeInterval, parent: SystemUptimeRecord? = nil) {
                self.start = start
                self.end = end
                self.parent = parent
            }
        }
        
        #Index<SystemUptimeRecord>([\.year, \.month])
        
        var year: Int
        var month: Int
        var day: Int
        var launch: TimeInterval
        var shutdown: TimeInterval
        
        @Relationship(deleteRule: .cascade, inverse: \SleepRecord.parent)
        var sleepRecords: [SleepRecord]
        
        init(year: Int, month: Int, day: Int, launch: TimeInterval = 0, shutdown: TimeInterval = 0, sleepRecords: [SleepRecord] = []) {
            self.year = year
            self.month = month
            self.day = day
            self.launch = launch
            self.shutdown = shutdown
            self.sleepRecords = sleepRecords
        }
    }
}

extension TimeCardSchema_v2_3 {
    @Model
    class SystemUptimeRecord_v2_3 {
        @Model
        class SleepRecord_v2_3 {
            var start: Date
            var end: Date
            var parent: SystemUptimeRecord_v2_3?
            
            init(start: Date, end: Date, parent: SystemUptimeRecord_v2_3? = nil) {
                self.start = start
                self.end = end
                self.parent = parent
            }
        }
        
        #Index<SystemUptimeRecord_v2_3>([\.year, \.month])
        
        var year: Int
        var month: Int
        var day: Int
        var launch: Date
        var shutdown: Date
        
        @Relationship(deleteRule: .cascade, inverse: \SleepRecord_v2_3.parent)
        var sleepRecords: [SleepRecord_v2_3]
        
        var sortedSleepRecords: [SleepRecord_v2_3] {
            sleepRecords.sorted { $0.start < $1.start }
        }
        
        init(year: Int, month: Int, day: Int, launch: Date, shutdown: Date, sleepRecords: [SleepRecord_v2_3] = []) {
            self.year = year
            self.month = month
            self.day = day
            self.launch = launch
            self.shutdown = shutdown
            self.sleepRecords = sleepRecords
        }
    }
}

extension TimeCardSchema_v3 {
    @Model
    class SystemUptimeRecord_v3 {
        @Model
        class SleepRecord_v3 {
            var id: UUID
            var start: Date
            var end: Date
            var parent: SystemUptimeRecord_v3?
            
            init(id: UUID = UUID(), start: Date, end: Date, parent: SystemUptimeRecord_v3? = nil) {
                self.id = id
                self.start = start
                self.end = end
                self.parent = parent
            }
        }
        
        typealias SleepRecord = SleepRecord_v3
        
        #Index<SystemUptimeRecord_v3>([\.id], [\.year, \.month])
        
        var id: UUID
        var year: Int
        var month: Int
        var day: Int
        var launch: Date
        var shutdown: Date
        
        @Relationship(deleteRule: .cascade, inverse: \SleepRecord_v3.parent)
        var sleepRecords: [SleepRecord_v3]
        
        var sortedSleepRecords: [SleepRecord_v3] {
            sleepRecords.sorted { $0.start < $1.start }
        }
        
        var uptimes: TimeInterval {
            var interval = shutdown.timeIntervalSince(launch)
            for sleep in self.sleepRecords {
                interval -= sleep.end.timeIntervalSince(sleep.start)
            }
            
            return interval
        }
        
        init(id: UUID = UUID(), year: Int, month: Int, day: Int, launch: Date, shutdown: Date, sleepRecords: [SleepRecord_v3] = []) {
            self.id = id
            self.year = year
            self.month = month
            self.day = day
            self.launch = launch
            self.shutdown = shutdown
            self.sleepRecords = sleepRecords
        }
    }
}

typealias SystemUptimeRecord = TimeCardSchema_v3.SystemUptimeRecord_v3
