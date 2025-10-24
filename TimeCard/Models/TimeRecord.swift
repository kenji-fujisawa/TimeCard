//
//  TimeRecord.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/01.
//

import Foundation
import SwiftData

@Model
class TimeRecord {
    @Model
    class BreakTime {
        var start: Date?
        var end: Date?
        
        init(start: Date? = nil, end: Date? = nil) {
            self.start = start
            self.end = end
        }
    }
    
    enum State {
        case OffWork
        case AtWork
        case AtBreak
    }
    
    #Index<TimeRecord>([\.year, \.month])
    
    var year: Int
    var month: Int
    var checkIn: Date?
    var checkOut: Date?
    var breakTimes: [BreakTime]
    
    var sortedBreakTimes: [BreakTime] {
        breakTimes.sorted { $0.start ?? .distantPast < $1.start ?? .distantPast }
    }
    
    var state: State {
        if checkIn == nil {
            return .OffWork
        }
        
        let latest = sortedBreakTimes.last
        if latest?.start != nil && latest?.end == nil {
            return .AtBreak
        }
        
        if checkOut == nil {
            return .AtWork
        }
        
        return .OffWork
    }
    
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
    
    init(year: Int, month: Int, checkIn: Date? = nil, checkOut: Date? = nil, breakTimes: [BreakTime] = []) {
        self.year = year
        self.month = month
        self.checkIn = checkIn
        self.checkOut = checkOut
        self.breakTimes = breakTimes
    }
}
