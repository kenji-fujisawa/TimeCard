//
//  CalendarRecord.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/29.
//

import Foundation

struct CalendarRecord: Identifiable {
    var id = UUID()
    
    var date: Date
    var records: [TimeRecord]
}
