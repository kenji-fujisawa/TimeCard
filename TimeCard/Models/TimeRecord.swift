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
    #Index<TimeRecord>([\.year, \.month])
    
    var year: Int
    var month: Int
    var checkIn: Date?
    var checkOut: Date?
    
    init(year: Int, month: Int, checkIn: Date? = nil, checkOut: Date? = nil) {
        self.year = year
        self.month = month
        self.checkIn = checkIn
        self.checkOut = checkOut
    }
}
