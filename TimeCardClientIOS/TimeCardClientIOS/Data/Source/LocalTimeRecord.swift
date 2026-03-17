//
//  LocalTimeRecord.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2026/03/11.
//

import Foundation
import SwiftData

@Model
class LocalTimeRecord {
    @Model
    class LocalBreakTime {
        var id: UUID
        var start: Date?
        var end: Date?
        var parent: LocalTimeRecord?
        
        init(id: UUID, start: Date? = nil, end: Date? = nil, parent: LocalTimeRecord? = nil) {
            self.id = id
            self.start = start
            self.end = end
            self.parent = parent
        }
    }
    
    #Index<LocalTimeRecord>([\.id], [\.year, \.month])
    
    var id: UUID
    var year: Int
    var month: Int
    var checkIn: Date?
    var checkOut: Date?
    
    @Relationship(deleteRule: .cascade, inverse: \LocalBreakTime.parent)
    var breakTimes: [LocalBreakTime]
    
    init(id: UUID, year: Int, month: Int, checkIn: Date? = nil, checkOut: Date? = nil, breakTimes: [LocalBreakTime]) {
        self.id = id
        self.year = year
        self.month = month
        self.checkIn = checkIn
        self.checkOut = checkOut
        self.breakTimes = breakTimes
    }
}
