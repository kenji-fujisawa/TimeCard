//
//  LocalTimeRecord.swift
//  TimeCard
//
//  Created by uhimania on 2026/02/24.
//

import Foundation
import SwiftData

extension TimeCardSchema_v1 {
    @Model
    class TimeRecord {
        @Model
        class BreakTime {
            var id: UUID
            var start: Date?
            var end: Date?
            var parent: TimeRecord?
            
            init(id: UUID = UUID(), start: Date? = nil, end: Date? = nil, parent: TimeRecord? = nil) {
                self.id = id
                self.start = start
                self.end = end
                self.parent = parent
            }
        }
        
        #Index<TimeRecord>([\.id], [\.year, \.month])
        
        var id: UUID
        var year: Int
        var month: Int
        var checkIn: Date?
        var checkOut: Date?
        
        @Relationship(deleteRule: .cascade, inverse: \BreakTime.parent)
        var breakTimes: [BreakTime]
        
        init(id: UUID = UUID(), year: Int, month: Int, checkIn: Date? = nil, checkOut: Date? = nil, breakTimes: [BreakTime] = []) {
            self.id = id
            self.year = year
            self.month = month
            self.checkIn = checkIn
            self.checkOut = checkOut
            self.breakTimes = breakTimes
        }
    }
}

typealias LocalTimeRecord = TimeCardSchema_v1.TimeRecord
