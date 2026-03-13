//
//  CalendarDetailView.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/31.
//

import SwiftUI

struct CalendarDetailView: View {
    @Environment(ToastViewModel.self) private var toast: ToastViewModel
    let viewModel: CalendarDetailViewModel
    
    var body: some View {
        VStack {
            Text(viewModel.date, format: .dateTime.month().day().weekday())
                .foregroundStyle(viewModel.date.isHoliday() ? .red : .black)
                .environment(\.locale, Locale(identifier: "ja_JP"))
            
            Form {
                ForEach(viewModel.records) { record in
                    TimeRecordView(record: record)
                }
                .onDelete(perform: viewModel.deleteItems)
                
                Button("勤怠を追加", systemImage: "plus") {
                    viewModel.addItem()
                }
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("button_add_time_record")
            }
            .toolbar {
                ToolbarItem {
                    EditButton()
                        .accessibilityIdentifier("button_edit")
                }
            }
        }
        .padding()
        .onDisappear() {
            viewModel.updateRecord()
        }
    }
    
    private struct TimeRecordView: View {
        @Bindable var record: CalendarDetailViewModel.TimeRecord
        
        var body: some View {
            Section {
                VStack {
                    DatePicker("出勤", selection: $record.checkIn, displayedComponents: [.date, .hourAndMinute])
                        .accessibilityIdentifier("date_check_in")
                    Divider()
                    DatePicker("退勤", selection: $record.checkOut, displayedComponents: [.date, .hourAndMinute])
                        .accessibilityIdentifier("date_check_out")
                }
                
                ForEach(record.breakTimes) { breakTime in
                    BreakTimeView(breakTime: breakTime)
                }
                .onDelete(perform: record.deleteItems)
                
                Button("休憩を追加", systemImage: "plus") {
                    record.addItem()
                }
                .frame(maxWidth: .infinity)
                .deleteDisabled(true)
                .accessibilityIdentifier("button_add_break_time")
            }
        }
    }
    
    private struct BreakTimeView: View {
        @Bindable var breakTime: CalendarDetailViewModel.BreakTime
        
        var body: some View {
            VStack {
                DatePicker("休憩開始", selection: $breakTime.start, displayedComponents: [.date, .hourAndMinute])
                    .accessibilityIdentifier("date_break_start")
                Divider()
                DatePicker("休憩終了", selection: $breakTime.end, displayedComponents: [.date, .hourAndMinute])
                    .accessibilityIdentifier("date_break_end")
            }
        }
    }
}

#Preview {
    let record = CalendarRecord(
        date: .now,
        records: [
            TimeRecord(
                id: UUID(),
                checkIn: .now,
                checkOut: .now,
                breakTimes: [
                    TimeRecord.BreakTime(
                        id: UUID(),
                        start: .now,
                        end: .now
                    ),
                    TimeRecord.BreakTime(
                        id: UUID(),
                        start: .now,
                        end: .now
                    )
                ]
            ),
            TimeRecord(
                id: UUID(),
                checkIn: .now,
                checkOut: .now,
                breakTimes: [
                    TimeRecord.BreakTime(
                        id: UUID(),
                        start: .now,
                        end: .now
                    ),
                ]
            )
        ]
    )
    let repository = FakeCalendarRecordRepository()
    let viewModel = CalendarDetailViewModel(repository, record)
    NavigationStack {
        CalendarDetailView(viewModel: viewModel)
            .environment(ToastViewModel())
    }
}

private class FakeCalendarRecordRepository: CalendarRecordRepository {
    func getRecordsStream(year: Int, month: Int) -> AsyncThrowingStream<[CalendarRecord], Error> {
        AsyncThrowingStream { _ in }
    }
    func updateRecord(_ record: CalendarRecord) async throws {}
}
