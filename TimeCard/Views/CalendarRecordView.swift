//
//  CalendarRecordView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/03.
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
                    } else {
                        Text(" ")
                    }
                }
            }
            
            VStack {
                ForEach(record.records) { record in
                    if record.checkOut != nil {
                        Text(interval(record: record), format: .timeWorked)
                    } else {
                        Text(" ")
                    }
                }
            }
            
            VStack {
                ForEach(record.records) { record in
                    ForEach(record.sortedBreakTimes) { breakTime in
                        if let start = breakTime.start {
                            Text(start, format: .dateTime.hour().minute())
                        } else {
                            Text(" ")
                        }
                    }
                }
            }
            
            VStack {
                ForEach(record.records) { record in
                    ForEach(record.sortedBreakTimes) { breakTime in
                        if breakTime.end != nil {
                            Text(interval(breakTime: breakTime), format: .timeWorked)
                        } else {
                            Text(" ")
                        }
                    }
                }
            }
            
            if record.timeWorked > 0 {
                Text(record.timeWorked, format: .timeWorked)
            } else {
                Text(" ")
            }
        }
        .font(.system(.headline, design: .monospaced))
        .fontWeight(.regular)
        
        Divider()
    }
    
    private func interval(record: TimeRecord) -> TimeInterval {
        interval(start: record.checkIn, end: record.checkOut)
    }
    
    private func interval(breakTime: TimeRecord.BreakTime) -> TimeInterval {
        interval(start: breakTime.start, end: breakTime.end)
    }
    
    private func interval(start: Date?, end: Date?) -> TimeInterval {
        guard let start = start else { return 0 }
        guard let end = end else { return 0 }
        return end.timeIntervalSince(Calendar.current.startOfDay(for: start))
    }
}

#Preview {
    let break1 = TimeRecord.BreakTime(start: .now, end: .now)
    let break2 = TimeRecord.BreakTime(start: .now)
    let rec1 = TimeRecord(year: Date.now.year, month: Date.now.month, checkIn: .now, checkOut: .now, breakTimes: [break1, break2])
    let rec2 = TimeRecord(year: Date.now.year, month: Date.now.month, checkIn: .now, breakTimes: [break1])
    let record = CalendarRecord(date: .now, records: [rec1, rec2])
    Grid {
        CalendarRecordView(record: record)
    }
}
