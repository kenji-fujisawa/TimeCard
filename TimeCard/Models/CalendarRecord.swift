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
    var records: [TimeRecord]
    var systemUptime: TimeInterval
    
    var timeWorked: TimeInterval {
        records.reduce(0) { partialResult, record in
            partialResult + record.timeWorked
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
