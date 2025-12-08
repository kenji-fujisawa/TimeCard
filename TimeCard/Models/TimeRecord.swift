//
//  TimeRecord.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/01.
//

import Foundation
import SwiftData

extension TimeCardSchema_v1 {
    @Model
    class TimeRecord: Encodable {
        @Model
        class BreakTime: Encodable {
            enum CodingKeys: String, CodingKey {
                case id, start, end
            }
            
            var id: UUID
            var start: Date?
            var end: Date?
            var parent: TimeRecord?
            
            init(start: Date? = nil, end: Date? = nil, parent: TimeRecord? = nil) {
                self.id = UUID()
                self.start = start
                self.end = end
                self.parent = parent
            }
            
            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(id, forKey: .id)
                try container.encode(start, forKey: .start)
                try container.encode(end, forKey: .end)
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case id, year, month, checkIn, checkOut, breakTimes
        }
        
        enum State {
            case OffWork
            case AtWork
            case AtBreak
        }
        
        #Index<TimeRecord>([\.year, \.month])
        
        var id: UUID
        var year: Int
        var month: Int
        var checkIn: Date?
        var checkOut: Date?
        
        @Relationship(deleteRule: .cascade, inverse: \BreakTime.parent)
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
            self.id = UUID()
            self.year = year
            self.month = month
            self.checkIn = checkIn
            self.checkOut = checkOut
            self.breakTimes = breakTimes
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(year, forKey: .year)
            try container.encode(month, forKey: .month)
            try container.encode(checkIn, forKey: .checkIn)
            try container.encode(checkOut, forKey: .checkOut)
            try container.encode(breakTimes, forKey: .breakTimes)
        }
    }
}

typealias TimeRecord = TimeCardSchema_v1.TimeRecord
