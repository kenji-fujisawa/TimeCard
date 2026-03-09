//
//  SystemUptimeRecord.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/15.
//

import Foundation

struct SystemUptimeRecord: Equatable {
    struct SleepRecord: Equatable {
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
    var launch: Date
    var shutdown: Date
    var sleepRecords: [SleepRecord]
    
    var uptime: TimeInterval {
        var interval = shutdown.timeIntervalSince(launch)
        for sleep in self.sleepRecords {
            interval -= sleep.end.timeIntervalSince(sleep.start)
        }
        
        return interval
    }
    
    init(id: UUID = UUID(), launch: Date, shutdown: Date, sleepRecords: [SleepRecord] = []) {
        self.id = id
        self.launch = launch
        self.shutdown = shutdown
        self.sleepRecords = sleepRecords
    }
}
