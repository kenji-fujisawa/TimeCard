//
//  SystemUptimeRecord.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/15.
//

import Foundation
import SwiftData

@Model
class SystemUptimeRecord {
    #Index<SystemUptimeRecord>([\.year, \.month])
    
    var year: Int
    var month: Int
    var day: Int
    var launch: TimeInterval
    var shutdown: TimeInterval
    
    init(year: Int, month: Int, day: Int, launch: TimeInterval = 0, shutdown: TimeInterval = 0) {
        self.year = year
        self.month = month
        self.day = day
        self.launch = launch
        self.shutdown = shutdown
    }
}
