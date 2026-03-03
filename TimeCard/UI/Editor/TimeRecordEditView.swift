//
//  TimeRecordEditView.swift
//  TimeCard
//
//  Created by uhimania on 2025/12/08.
//

import SwiftUI

struct TimeRecordEditView: View {
    @Binding var record: CalendarRecord
    @State private var selectedId: TimeRecord.ID? = nil
    
    var body: some View {
        NavigationSplitView {
            SidebarView(record: $record, selectedId: $selectedId)
        } detail: {
            if let index = record.timeRecords.firstIndex(where: { $0.id == selectedId }) {
                DetailView(record: $record.timeRecords[index])
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .onAppear() {
            selectedId = record.timeRecords.first?.id
        }
    }
    
    private struct SidebarView: View {
        @Binding var record: CalendarRecord
        @Binding var selectedId: TimeRecord.ID?
        @State private var recordToRemove: TimeRecord? = nil
        
        var body: some View {
            List(selection: $selectedId) {
                Section("出勤時刻") {
                    ForEach($record.timeRecords) { $record in
                        if let checkIn = record.checkIn {
                            HStack {
                                Text(checkIn.formatted(.dateTime.hour().minute()))
                                .accessibilityIdentifier("nav_link")
                                
                                Spacer()
                                
                                if recordToRemove == record {
                                    Button(role: .destructive) {
                                        removeRecord(record: record)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.red)
                                    }
                                    .accessibilityIdentifier("button_remove_time_record")
                                } else {
                                    Button {
                                        recordToRemove = record
                                    } label: {
                                        Image(systemName: "minus")
                                    }
                                    .accessibilityIdentifier("button_remove_time_confirm")
                                }
                            }
                            .tag(record.id)
                        }
                    }
                }
                
                Button("追加", systemImage: "plus") {
                    addRecord()
                }
                .font(.footnote)
                .accessibilityIdentifier("button_add_time_record")
            }
        }
        
        private func addRecord() {
            let date = record.date
            let record = TimeRecord(year: date.year, month: date.month, checkIn: date, checkOut: date)
            self.record.timeRecords.append(record)
            selectedId = record.id
        }
        
        private func removeRecord(record: TimeRecord) {
            self.record.timeRecords.removeAll(where: { $0 == record })
            recordToRemove = nil
            if selectedId == record.id {
                selectedId = self.record.timeRecords.first?.id
            }
        }
    }
    
    private struct DetailView: View {
        @Binding var record: TimeRecord
        @State private var recordToRemove: TimeRecord.BreakTime? = nil
        
        var body: some View {
            VStack(alignment: .leading) {
                Form {
                    DatePicker("出勤", selection: $record.checkIn.bindUnwrap(defaultValue: .now), displayedComponents: [.date, .hourAndMinute])
                        .accessibilityIdentifier("date_check_in")
                    DatePicker("退勤", selection: $record.checkOut.bindUnwrap(defaultValue: .now), displayedComponents: [.date, .hourAndMinute])
                        .accessibilityIdentifier("date_check_out")
                }
                .padding()
                
                List {
                    ForEach($record.breakTimes) { $breakTime in
                        Section {
                            BreakTimeView(breakTime: $breakTime)
                        } header: {
                            HStack {
                                Text("休憩")
                                
                                Spacer()
                                
                                if recordToRemove == breakTime {
                                    Button(role: .destructive) {
                                        record.breakTimes.removeAll(where: { $0 == breakTime })
                                        recordToRemove = nil
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.red)
                                    }
                                    .accessibilityIdentifier("button_remove_break_time")
                                } else {
                                    Button {
                                        recordToRemove = breakTime
                                    } label: {
                                        Image(systemName: "minus")
                                    }
                                    .accessibilityIdentifier("button_remove_break_confirm")
                                }
                            }
                        }
                    }
                    
                    Button("休憩を追加", systemImage: "plus") {
                        let date = record.checkIn
                        let breakTime = TimeRecord.BreakTime(start: date, end: date)
                        record.breakTimes.append(breakTime)
                    }
                    .font(.footnote)
                    .accessibilityIdentifier("button_add_break_time")
                }
            }
        }
    }
    
    private struct BreakTimeView: View {
        @Binding var breakTime: TimeRecord.BreakTime
        
        var body: some View {
            Form {
                DatePicker("開始", selection: $breakTime.start.bindUnwrap(defaultValue: .now), displayedComponents: [.date, .hourAndMinute])
                    .accessibilityIdentifier("date_break_start")
                DatePicker("終了", selection: $breakTime.end.bindUnwrap(defaultValue: .now), displayedComponents: [.date, .hourAndMinute])
                    .accessibilityIdentifier("date_break_end")
            }
        }
    }
}

#Preview {
    @Previewable @State var record = CalendarRecord(
        date: .now,
        timeRecords: [
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
        uptimeRecords: []
    )
    TimeRecordEditView(record: $record)
}
