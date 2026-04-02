//
//  CalendarRecordView.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/29.
//

import SwiftUI

struct CalendarRecordView: View {
    let record: CalendarViewModel.CalendarRecord
    
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
                        Text(record.interval, format: .timeWorked)
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
                            Text(breakTime.interval, format: .timeWorked)
                                .accessibilityIdentifier("text_break_end")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let record = CalendarViewModel.CalendarRecord(
        date: .now,
        records: [
            CalendarViewModel.TimeRecord(
                checkIn: .now,
                checkOut: Date(timeIntervalSinceNow: 26 * 60 * 60),
                breakTimes: [
                    CalendarViewModel.BreakTime(
                        start: .now,
                        end: Date(timeIntervalSinceNow: 25 * 60 * 60)
                    ),
                    CalendarViewModel.BreakTime(
                        start: .now
                    )
                ]
            ),
            CalendarViewModel.TimeRecord(
                checkIn: .now,
                breakTimes: [
                    CalendarViewModel.BreakTime(
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
