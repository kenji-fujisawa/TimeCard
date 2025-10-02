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
    var checkIn: Date?
    var checkOut: Date?
    
    init(checkIn: Date? = nil, checkOut: Date? = nil) {
        self.checkIn = checkIn
        self.checkOut = checkOut
    }
}
