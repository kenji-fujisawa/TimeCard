//
//  TimeRecord.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/29.
//

import Foundation

struct TimeRecord: Codable {
    struct BreakTime: Codable {
        var start: Date?
        var end: Date?
    }
    
    var year: Int
    var month: Int
    var checkIn: Date?
    var checkOut: Date?
    var breakTimes: [BreakTime]
}
