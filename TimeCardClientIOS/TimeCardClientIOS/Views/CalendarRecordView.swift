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
                .accessibilityIdentifier("text_date")
            
            VStack {
                ForEach(record.records) { record in
                    if let checkIn = record.checkIn {
                        Text(checkIn, format: .dateTime.hour().minute())
                            .accessibilityIdentifier("text_check_in")
                    }
                }
            }
            
            VStack {
                ForEach(record.records) { record in
                    if record.checkOut != nil {
                        Text(interval(record: record), format: .timeWorked)
                            .accessibilityIdentifier("text_check_out")
                    }
                }
            }
            
            VStack {
                ForEach(record.records) { record in
                    ForEach(record.breakTimes) { breakTime in
                        if let start = breakTime.start {
                            Text(start, format: .dateTime.hour().minute())
                                .accessibilityIdentifier("text_break_start")
                        }
                    }
                }
            }
            
            VStack {
                ForEach(record.records) { record in
                    ForEach(record.breakTimes) { breakTime in
                        if breakTime.end != nil {
                            Text(interval(breakTime: breakTime), format: .timeWorked)
                                .accessibilityIdentifier("text_break_end")
                        }
                    }
                }
            }
        }
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
    let record = CalendarRecord(
        date: .now,
        records: [
            TimeRecord(
                id: UUID(),
                year: Date.now.year,
                month: Date.now.month,
                checkIn: .now,
                checkOut: Date(timeIntervalSinceNow: 26 * 60 * 60),
                breakTimes: [
                    TimeRecord.BreakTime(
                        id: UUID(),
                        start: .now,
                        end: Date(timeIntervalSinceNow: 25 * 60 * 60)
                    ),
                    TimeRecord.BreakTime(
                        id: UUID(),
                        start: .now
                    )
                ]
            ),
            TimeRecord(
                id: UUID(),
                year: Date.now.year,
                month: Date.now.month,
                checkIn: .now,
                breakTimes: [
                    TimeRecord.BreakTime(
                        id: UUID(),
                        start: .now,
                        end: Date(timeIntervalSinceNow: 25 * 60 * 60)
                    )
                ]
            )
        ]
    )
    Grid {
        CalendarRecordView(record: record)
    }
}
