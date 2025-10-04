//
//  CalendarRecord.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/03.
//

import Foundation

struct CalendarRecord: Identifiable {
    var id = UUID()
    
    var date: Date
    var records: [TimeRecord]
}
