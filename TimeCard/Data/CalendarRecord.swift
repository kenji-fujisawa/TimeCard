//
//  CalendarRecord.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/03.
//

import Foundation

struct CalendarRecord: Identifiable {
    var id = UUID()
    
    var date: Date
    var timeRecords: [TimeRecord]
    var uptimeRecords: [SystemUptimeRecord]
    
    var timeWorked: TimeInterval {
        timeRecords.reduce(0) { partialResult, record in
            partialResult + record.timeWorked
        }
    }
    
    var systemUptime: TimeInterval {
        uptimeRecords.reduce(0) { partialResult, record in
            partialResult + record.uptime
        }
    }
}

extension [CalendarRecord] {
    var timeWorkedSum: TimeInterval {
        self.reduce(0) { partialResult, record in
            partialResult + record.timeWorked
        }
    }
    
    var systemUptimeSum: TimeInterval {
        self.reduce(0) { partialResult, record in
            partialResult + record.systemUptime
        }
    }
}
