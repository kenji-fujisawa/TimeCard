//
//  CalendarDetailView.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/31.
//

import SwiftUI

struct CalendarDetailView: View {
    @EnvironmentObject private var toast: ToastViewModel
    @State var record: CalendarRecord
    @ObservedObject var model: CalendarViewModel
    
    var body: some View {
        VStack {
            Text(record.date, format: .dateTime.month().day().weekday())
                .foregroundStyle(record.date.isHoliday() ? .red : .black)
                .environment(\.locale, Locale(identifier: "ja_JP"))
            
            Form {
                ForEach($record.records) { $record in
                    TimeRecordView(record: $record)
                }
                .onDelete(perform: deleteItems)
                
                Button("勤怠を追加", systemImage: "plus") {
                    addItem()
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
            model.updateRecord(record: record)
        }
    }
    
    private func addItem() {
        let rec = TimeRecord(id: UUID(), year: record.date.year, month: record.date.month, checkIn: record.date, checkOut: record.date, breakTimes: [])
        record.records.append(rec)
    }
    
    private func deleteItems(indexes: IndexSet) {
        record.records.remove(atOffsets: indexes)
    }
    
    private struct TimeRecordView: View {
        @Binding var record: TimeRecord
        
        var body: some View {
            Section {
                VStack {
                    DatePicker("出勤", selection: $record.checkIn.bindUnwrap(defaultValue: .now), displayedComponents: [.date, .hourAndMinute])
                        .accessibilityIdentifier("date_check_in")
                    Divider()
                    DatePicker("退勤", selection: $record.checkOut.bindUnwrap(defaultValue: .now), displayedComponents: [.date, .hourAndMinute])
                        .accessibilityIdentifier("date_check_out")
                }
                
                ForEach($record.breakTimes) { $breakTime in
                    BreakTimeView(breakTime: $breakTime)
                }
                .onDelete(perform: deleteItems)
                
                Button("休憩を追加", systemImage: "plus") {
                    record.breakTimes.append(TimeRecord.BreakTime(id: UUID(), start: record.checkIn, end: record.checkIn))
                }
                .frame(maxWidth: .infinity)
                .deleteDisabled(true)
                .accessibilityIdentifier("button_add_break_time")
            }
        }
        
        private func deleteItems(indexes: IndexSet) {
            record.breakTimes.remove(atOffsets: indexes)
        }
    }
    
    private struct BreakTimeView: View {
        @Binding var breakTime: TimeRecord.BreakTime
        
        var body: some View {
            VStack {
                DatePicker("休憩開始", selection: $breakTime.start.bindUnwrap(defaultValue: .now), displayedComponents: [.date, .hourAndMinute])
                    .accessibilityIdentifier("date_break_start")
                Divider()
                DatePicker("休憩終了", selection: $breakTime.end.bindUnwrap(defaultValue: .now), displayedComponents: [.date, .hourAndMinute])
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
                year: Date.now.year,
                month: Date.now.month,
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
                year: Date.now.year,
                month: Date.now.month,
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
    let model = CalendarViewModel(repository: repository)
    NavigationStack {
        CalendarDetailView(record: record, model: model)
            .environmentObject(ToastViewModel())
    }
}

private class FakeCalendarRecordRepository: CalendarRecordRepository {
    func getRecords(year: Int, month: Int) -> AsyncThrowingStream<[CalendarRecord], Error> {
        AsyncThrowingStream { _ in }
    }
    
    func updateRecord(source: [CalendarRecord], record: CalendarRecord) async throws {
    }
}
