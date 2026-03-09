//
//  RecordEditView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/07.
//

import SwiftUI

struct RecordEditView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: RecordEditViewModel
    
    var body: some View {
        TabView {
            Tab("労働時間", systemImage: "person.circle.fill") {
                TimeRecordEditView(viewModel: viewModel.timeViewModel)
            }
            Tab("システム稼働時間", systemImage: "power.circle.fill") {
                SystemUptimeRecordEditView(viewModel: viewModel.uptimeViewModel)
            }
        }
        .padding()
        .toolbar {
            ToolbarItem {
                Button("閉じる", systemImage: "xmark") {
                    viewModel.update()
                    dismiss()
                }
                .accessibilityIdentifier("button_close")
            }
        }
    }
}

#Preview {
    let repository = FakeCalendarRecordRepository()
    let viewModel = RecordEditViewModel(repository, .now)
    RecordEditView(viewModel: viewModel)
}

private class FakeCalendarRecordRepository: CalendarRecordRepository {
    func getRecordsStream(year: Int, month: Int) -> AsyncStream<[CalendarRecord]> {
        AsyncStream { _ in }
    }
    
    func getRecord(year: Int, month: Int, day: Int) throws -> CalendarRecord {
        CalendarRecord(
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
    }
    
    func updateRecord(_ record: CalendarRecord) throws {}
}
