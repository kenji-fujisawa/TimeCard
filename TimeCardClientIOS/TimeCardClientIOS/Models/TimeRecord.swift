//
//  TimeRecord.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/29.
//

import Foundation

struct TimeRecord: Codable, Identifiable, Equatable {
    struct BreakTime: Codable, Identifiable, Equatable {
        var id: UUID
        var start: Date?
        var end: Date?
    }
    
    var id: UUID
    var year: Int
    var month: Int
    var checkIn: Date?
    var checkOut: Date?
    var breakTimes: [BreakTime]
}
