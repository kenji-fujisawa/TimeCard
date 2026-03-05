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
    var viewModel: CalendarViewModel
    
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
                    viewModel.update(record: record)
                    dismiss()
                }
                .accessibilityIdentifier("button_close")
            }
        }
    }
}

#Preview {
    let record = CalendarRecord(
        date: .now,
        timeRecords: [
            TimeRecord(
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
                checkIn: .now,
                breakTimes: [
                    TimeRecord.BreakTime(
                        start: .now,
                        end: .now
                    )
                ]
            )
        ],
        uptimeRecords: [
            SystemUptimeRecord(
                launch: .now,
                shutdown: .now
            )
        ]
    )
    let repository = FakeCalendarRecordRepository()
    let viewModel = CalendarViewModel(repository)
    RecordEditView(record: record, viewModel: viewModel)
}

private class FakeCalendarRecordRepository: CalendarRecordRepository {
    func getRecordsStream(year: Int, month: Int) -> AsyncStream<[CalendarRecord]> {
        AsyncStream { _ in }
    }
    
    func updateRecord(_ record: CalendarRecord) throws {}
}
