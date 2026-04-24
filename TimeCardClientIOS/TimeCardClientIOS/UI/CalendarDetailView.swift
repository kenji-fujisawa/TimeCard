//
//  CalendarDetailView.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/31.
//

import SwiftUI

struct CalendarDetailView: View {
    @Environment(ToastViewModel.self) private var toast: ToastViewModel
    @State private var viewModel: CalendarDetailViewModel
    
    init(repository: CalendarRecordRepository, date: Date) {
        self.viewModel = CalendarDetailViewModel(repository, date)
    }
    
    var body: some View {
        VStack {
            Text(viewModel.date, format: .dateTime.month().day().weekday())
                .foregroundStyle(viewModel.date.isHoliday() ? .red : .primary)
                .environment(\.locale, Locale(identifier: "ja_JP"))
            
            Form {
                ForEach(viewModel.records) { record in
                    TimeRecordView(record: record, valid: viewModel.isValid(record))
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
                ToolbarItem {
                    Button("Save", systemImage: "square.and.arrow.down") {
                        viewModel.updateRecord()
                    }
                    .disabled(!viewModel.isValid())
                    .accessibilityIdentifier("button_save")
                }
            }
        }
        .padding()
    }
    
    private struct TimeRecordView: View {
        @Bindable var record: CalendarDetailViewModel.TimeRecord
        let valid: Bool
        
        var body: some View {
            Section {
                VStack {
                    DatePicker("出勤", selection: $record.checkIn, displayedComponents: [.date, .hourAndMinute])
                        .isValid(valid)
                        .accessibilityIdentifier("date_check_in")
                    Divider()
                    DatePicker("退勤", selection: $record.checkOut, displayedComponents: [.date, .hourAndMinute])
                        .isValid(valid)
                        .accessibilityIdentifier("date_check_out")
                }
                
                ForEach(record.breakTimes) { breakTime in
                    BreakTimeView(breakTime: breakTime, valid: record.isValid(breakTime))
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
        let valid: Bool
        
        var body: some View {
            VStack {
                DatePicker("休憩開始", selection: $breakTime.start, displayedComponents: [.date, .hourAndMinute])
                    .isValid(valid)
                    .accessibilityIdentifier("date_break_start")
                Divider()
                DatePicker("休憩終了", selection: $breakTime.end, displayedComponents: [.date, .hourAndMinute])
                    .isValid(valid)
                    .accessibilityIdentifier("date_break_end")
            }
        }
    }
}

private struct ValidModifier: ViewModifier {
    let valid: Bool
    
    func body(content: Content) -> some View {
        if valid {
            content
        } else {
            HStack {
                content
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(.red)
            }
        }
    }
}

private extension View {
    func isValid(_ valid: Bool) -> some View {
        self.modifier(ValidModifier(valid: valid))
    }
}

#Preview {
    let repository = FakeCalendarRecordRepository()
    NavigationStack {
        CalendarDetailView(repository: repository, date: .now)
            .environment(ToastViewModel())
    }
}

private class FakeCalendarRecordRepository: CalendarRecordRepository {
    func getRecordsStream(year: Int, month: Int) -> AsyncThrowingStream<[CalendarRecord], Error> {
        AsyncThrowingStream { _ in }
    }
    
    func getRecord(year: Int, month: Int, day: Int) throws -> CalendarRecord {
        CalendarRecord(
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
    }
    
    func updateRecord(_ record: CalendarRecord) async throws {}
}
