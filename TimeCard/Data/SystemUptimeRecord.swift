//
//  SystemUptimeRecord.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/15.
//

import Foundation

struct SystemUptimeRecord: Identifiable, Hashable, Equatable {
    struct SleepRecord: Identifiable, Hashable, Equatable {
        var id: UUID
        var start: Date
        var end: Date
        
        init(id: UUID = UUID(), start: Date, end: Date) {
            self.id = id
            self.start = start
            self.end = end
        }
    }
    
    var id: UUID
    var year: Int
    var month: Int
    var day: Int
    var launch: Date
    var shutdown: Date
    var sleepRecords: [SleepRecord]
    
    var uptimes: TimeInterval {
        var interval = shutdown.timeIntervalSince(launch)
        for sleep in self.sleepRecords {
            interval -= sleep.end.timeIntervalSince(sleep.start)
        }
        
        return interval
    }
    
    init(id: UUID = UUID(), year: Int, month: Int, day: Int, launch: Date, shutdown: Date, sleepRecords: [SleepRecord] = []) {
        self.id = id
        self.year = year
        self.month = month
        self.day = day
        self.launch = launch
        self.shutdown = shutdown
        self.sleepRecords = sleepRecords
    }
}
