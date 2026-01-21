//
//  CalendarRecordView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/03.
//

import SwiftUI

struct CalendarRecordView: View {
    let record: CalendarRecord
    let fixed: Bool
    @Binding var recordToEdit: CalendarRecord?
    
    var body: some View {
        GridRow {
            Text(record.date, format: .dayWithWeekday)
                .foregroundStyle(record.date.isHoliday() ? .red : .black)
                .accessibilityIdentifier("text_date")
            
            ZStack {
                VStack {
                    ForEach(record.records) { record in
                        if let checkIn = record.checkIn {
                            Text(checkIn, format: .dateTime.hour().minute())
                                .accessibilityIdentifier("text_check_in")
                        }
                    }
                }
                Text("00:00")
                    .opacity(0)
            }
            
            ZStack {
                VStack {
                    ForEach(record.records) { record in
                        if record.checkOut != nil {
                            Text(interval(record: record), format: .timeWorked)
                                .accessibilityIdentifier("text_check_out")
                        }
                    }
                }
                Text("00:00")
                    .opacity(0)
            }
            
            ZStack {
                VStack {
                    ForEach(record.records) { record in
                        ForEach(record.sortedBreakTimes) { breakTime in
                            if let start = breakTime.start {
                                Text(start, format: .dateTime.hour().minute())
                                    .accessibilityIdentifier("text_break_start")
                            }
                        }
                    }
                }
                Text("00:00")
                    .opacity(0)
            }
            
            ZStack {
                VStack {
                    ForEach(record.records) { record in
                        ForEach(record.sortedBreakTimes) { breakTime in
                            if breakTime.end != nil {
                                Text(interval(breakTime: breakTime), format: .timeWorked)
                                    .accessibilityIdentifier("text_break_end")
                            }
                        }
                    }
                }
                Text("00:00")
                    .opacity(0)
            }
            
            ZStack {
                if record.timeWorked > 0 {
                    Text(record.timeWorked, format: .timeWorked)
                        .accessibilityIdentifier("text_time_worked")
                }
                Text("00:00")
                    .opacity(0)
            }
            
            ZStack {
                if record.systemUptime > 0 {
                    Text(record.systemUptime, format: .timeWorked)
                        .accessibilityIdentifier("text_system_uptime")
                }
                Text("00:00")
                    .opacity(0)
            }
            
            if fixed {
                Button("edit") {
                    recordToEdit = record
                }
                .accessibilityIdentifier("button_edit")
            }
        }
        .font(.system(.headline, design: .monospaced))
        .fontWeight(.regular)
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
    @Previewable @State var recordToEdit: CalendarRecord?
    let record = CalendarRecord(
        date: .now,
        records: [
            TimeRecord(
                year: Date.now.year,
                month: Date.now.month,
                checkIn: .now,
                checkOut: Date(timeInterval: 26 * 60 * 60, since: .now),
                breakTimes: [
                    TimeRecord.BreakTime(
                        start: .now,
                        end: Date(timeInterval: 25 * 60 * 60, since: .now)
                    ),
                    TimeRecord.BreakTime(
                        start: .now
                    )
                ]
            ),
            TimeRecord(
                year: Date.now.year,
                month: Date.now.month,
                checkIn: .now,
                breakTimes: [
                    TimeRecord.BreakTime(
                        start: .now,
                        end: Date(timeInterval: 25 * 60 * 60, since: .now)
                    )
                ]
            )
        ],
        systemUptimeRecords: [
            SystemUptimeRecord(
                year: Date.now.year,
                month: Date.now.month,
                day: Date.now.day,
                launch: .now,
                shutdown: .now
            )
        ]
    )
    Grid {
        CalendarRecordView(record: record, fixed: true, recordToEdit: $recordToEdit)
    }
}
