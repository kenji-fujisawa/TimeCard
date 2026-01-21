//
//  RecordEditView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/07.
//

import SwiftUI

struct RecordEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State var record: CalendarRecord
    @ObservedObject var calendar: CalendarViewModel
    
    init(record: CalendarRecord, calendar: CalendarViewModel) {
        self.record = record.copy()
        self.calendar = calendar
    }
    
    var body: some View {
        TabView {
            Tab("労働時間", systemImage: "person.circle.fill") {
                TimeRecordEditView(record: $record)
            }
            Tab("システム稼働時間", systemImage: "power.circle.fill") {
                SystemUptimeRecordEditView(record: $record)
            }
        }
        .padding()
        .toolbar {
            ToolbarItem {
                Button("閉じる", systemImage: "xmark") {
                    calendar.update(record: record)
                    dismiss()
                }
                .accessibilityIdentifier("button_close")
            }
        }
    }
}

extension CalendarRecord {
    func copy() -> CalendarRecord {
        CalendarRecord(
            date: self.date,
            records: self.records.map { $0.copy() },
            systemUptimeRecords: self.systemUptimeRecords.map { $0.copy() }
        )
    }
}

#Preview {
    let record = CalendarRecord(
        date: .now,
        records: [
            TimeRecord(
                year: Date.now.year,
                month: Date.now.month,
                checkIn: .now,
                checkOut: .now,
                breakTimes: [
                    TimeRecord.BreakTime(
                        start: .now,
                        end: .now
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
                        end: .now
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
    let repository = FakeCalendarRecordRepository()
    let calendar = CalendarViewModel(repository: repository)
    RecordEditView(record: record, calendar: calendar)
}

private class FakeCalendarRecordRepository: CalendarRecordRepository {
    func getRecords(year: Int, month: Int) -> AsyncStream<[CalendarRecord]> {
        AsyncStream { _ in }
    }
    
    func updateRecord(source: [CalendarRecord], record: CalendarRecord) throws {}
}
