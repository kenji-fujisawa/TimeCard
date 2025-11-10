//
//  CalendarRecordView.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/29.
//

import SwiftUI

struct CalendarRecordView: View {
    let record: CalendarRecord
    
    var body: some View {
        GridRow {
            Text(record.date, format: .dayWithWeekday)
                .foregroundStyle(record.date.isHoliday() ? .red : .black)
            
            VStack {
                ForEach(record.records) { record in
                    if let checkIn = record.checkIn {
                        Text(checkIn, format: .dateTime.hour().minute())
                    }
                }
            }
            
            VStack {
                ForEach(record.records) { record in
                    if let checkOut = record.checkOut {
                        Text(checkOut, format: .dateTime.hour().minute())
                    }
                }
            }
            
            VStack {
                ForEach(record.records) { record in
                    ForEach(record.breakTimes) { breakTime in
                        if let start = breakTime.start {
                            Text(start, format: .dateTime.hour().minute())
                        }
                    }
                }
            }
            
            VStack {
                ForEach(record.records) { record in
                    ForEach(record.breakTimes) { breakTime in
                        if let end = breakTime.end {
                            Text(end, format: .dateTime.hour().minute())
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let break1 = TimeRecord.BreakTime(id: UUID(), start: .now, end: .now)
    let break2 = TimeRecord.BreakTime(id: UUID(), start: .now)
    let rec1 = TimeRecord(id: UUID(), year: Date.now.year, month: Date.now.month, checkIn: .now, checkOut: .now, breakTimes: [break1, break2])
    let rec2 = TimeRecord(id: UUID(), year: Date.now.year, month: Date.now.month, checkIn: .now, breakTimes: [break1])
    let record = CalendarRecord(date: .now, records: [rec1, rec2])
    Grid {
        CalendarRecordView(record: record)
    }
}
