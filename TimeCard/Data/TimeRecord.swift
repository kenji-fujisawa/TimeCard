//
//  TimeRecord.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/01.
//

import Foundation

struct TimeRecord: Identifiable, Hashable, Equatable, Encodable {
    struct BreakTime: Identifiable, Hashable, Equatable, Encodable {
        var id: UUID
        var start: Date?
        var end: Date?
        
        init(id: UUID = UUID(), start: Date? = nil, end: Date? = nil) {
            self.id = id
            self.start = start
            self.end = end
        }
    }
    
    var id: UUID
    var year: Int
    var month: Int
    var checkIn: Date?
    var checkOut: Date?
    var breakTimes: [BreakTime]
    
    var timeWorked: TimeInterval {
        guard let checkIn = self.checkIn else { return 0 }
        guard let checkOut = self.checkOut else { return 0 }
        
        var interval = checkOut.timeIntervalSince(checkIn)
        for breakTime in self.breakTimes {
            guard let start = breakTime.start else { continue }
            guard let end = breakTime.end else { continue }
            interval -= end.timeIntervalSince(start)
        }
        
        return interval
    }
    
    init(id: UUID = UUID(), year: Int, month: Int, checkIn: Date? = nil, checkOut: Date? = nil, breakTimes: [BreakTime] = []) {
        self.id = id
        self.year = year
        self.month = month
        self.checkIn = checkIn
        self.checkOut = checkOut
        self.breakTimes = breakTimes
    }
}
