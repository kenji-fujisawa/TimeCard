//
//  TimeRecord.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/29.
//

import Foundation

struct TimeRecord: Codable, Equatable {
    struct BreakTime: Codable, Equatable {
        var id: UUID
        var start: Date?
        var end: Date?
    }
    
    var id: UUID
    var checkIn: Date?
    var checkOut: Date?
    var breakTimes: [BreakTime]
}
