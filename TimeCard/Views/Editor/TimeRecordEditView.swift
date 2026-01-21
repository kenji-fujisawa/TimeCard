//
//  TimeRecordEditView.swift
//  TimeCard
//
//  Created by uhimania on 2025/12/08.
//

import SwiftUI

struct TimeRecordEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var record: CalendarRecord
    @State private var selected: TimeRecord? = nil
    
    var body: some View {
        NavigationSplitView {
            SidebarView(record: $record, selected: $selected)
        } detail: {
            if let record = selected {
                DetailView(record: record)
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .onAppear() {
            selected = record.records.first
        }
    }
    
    private struct SidebarView: View {
        @Environment(\.modelContext) private var context
        @Binding var record: CalendarRecord
        @Binding var selected: TimeRecord?
        @State private var recordToRemove: TimeRecord? = nil
        
        var body: some View {
            List(selection: $selected) {
                Section("出勤時刻") {
                    ForEach(record.records) { record in
                        if let checkIn = record.checkIn {
                            HStack {
                                NavigationLink(checkIn.formatted(.dateTime.hour().minute())) {
                                    DetailView(record: record)
                                }
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
                            .tag(record)
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
            context.insert(record)
            self.record.records.append(record)
            selected = record
        }
        
        private func removeRecord(record: TimeRecord) {
            context.delete(record)
            self.record.records.removeAll(where: { $0 == record })
            recordToRemove = nil
            if selected == record {
                selected = self.record.records.first
            }
        }
    }
    
    private struct DetailView: View {
        @Bindable var record: TimeRecord
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
                    ForEach(record.sortedBreakTimes) { breakTime in
                        Section {
                            BreakTimeView(breakTime: breakTime)
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
        @Bindable var breakTime: TimeRecord.BreakTime
        
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
        systemUptimeRecords: []
    )
    TimeRecordEditView(record: $record)
}
