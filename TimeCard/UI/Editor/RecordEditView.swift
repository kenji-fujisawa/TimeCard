//
//  RecordEditView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/07.
//

import SwiftUI

struct RecordEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RecordEditViewModel
    
    init(repository: CalendarRecordRepository, date: Date) {
        self.viewModel = RecordEditViewModel(repository, date)
    }
    
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
                Button("保存", systemImage: "square.and.arrow.down") {
                    viewModel.update()
                }
                .disabled(!viewModel.isValid())
                .accessibilityIdentifier("button_save")
            }
            ToolbarItem {
                Button("閉じる", systemImage: "xmark") {
                    dismiss()
                }
                .accessibilityIdentifier("button_close")
            }
        }
    }
}

#Preview {
    let repository = FakeCalendarRecordRepository()
    RecordEditView(repository: repository, date: .now)
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
