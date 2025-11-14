//
//  SystemUptimeRecord.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/15.
//

import Foundation
import SwiftData

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
    
    var sortedSleepRecords: [SleepRecord] {
        sleepRecords.sorted { $0.start < $1.start }
    }
    
    var uptimes: TimeInterval {
        var interval = self.shutdown - self.launch
        for sleep in self.sleepRecords {
            interval -= sleep.end - sleep.start
        }
        
        return interval
    }
    
    init(year: Int, month: Int, day: Int, launch: TimeInterval = 0, shutdown: TimeInterval = 0, sleepRecords: [SleepRecord] = []) {
        self.year = year
        self.month = month
        self.day = day
        self.launch = launch
        self.shutdown = shutdown
        self.sleepRecords = sleepRecords
    }
}
