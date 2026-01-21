//
//  SystemUptimeRecordEditView.swift
//  TimeCard
//
//  Created by uhimania on 2025/12/08.
//

import SwiftUI

struct SystemUptimeRecordEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var record: CalendarRecord
    @State private var selected: SystemUptimeRecord? = nil
    
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
            selected = record.systemUptimeRecords.first
        }
    }
    
    private struct SidebarView: View {
        @Environment(\.modelContext) private var context
        @Binding var record: CalendarRecord
        @Binding var selected: SystemUptimeRecord?
        @State private var recordToRemove: SystemUptimeRecord? = nil
        
        var body: some View {
            List(selection: $selected) {
                Section("起動時間") {
                    ForEach(record.systemUptimeRecords) { record in
                        HStack {
                            NavigationLink(record.launch.formatted(.dateTime.hour().minute())) {
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
                                .accessibilityIdentifier("button_remove_uptime_record")
                            } else {
                                Button {
                                    recordToRemove = record
                                } label: {
                                    Image(systemName: "minus")
                                }
                                .accessibilityIdentifier("button_remove_uptime_confirm")
                            }
                        }
                        .tag(record)
                    }
                }
                
                Button("追加", systemImage: "plus") {
                    addRecord()
                }
                .font(.footnote)
                .accessibilityIdentifier("button_add_uptime_record")
            }
        }
        
        private func addRecord() {
            let date = record.date
            let record = SystemUptimeRecord(year: date.year, month: date.month, day: date.day, launch: date, shutdown: date)
            context.insert(record)
            self.record.systemUptimeRecords.append(record)
            selected = record
        }
        
        private func removeRecord(record: SystemUptimeRecord) {
            context.delete(record)
            self.record.systemUptimeRecords.removeAll(where: { $0 == record })
            recordToRemove = nil
            if selected == record {
                selected = self.record.systemUptimeRecords.first
            }
        }
    }
    
    private struct DetailView: View {
        @Bindable var record: SystemUptimeRecord
        @State private var recordToRemove: SystemUptimeRecord.SleepRecord? = nil
        
        var body: some View {
            VStack(alignment: .leading) {
                Form {
                    DatePicker("起動", selection: $record.launch, displayedComponents: [.date, .hourAndMinute])
                        .accessibilityIdentifier("date_launch")
                    DatePicker("終了", selection: $record.shutdown, displayedComponents: [.date, .hourAndMinute])
                        .accessibilityIdentifier("date_shutdown")
                }
                .padding()
                
                List {
                    ForEach(record.sortedSleepRecords) { sleepRecord in
                        Section {
                            SleepRecordView(sleepRecord: sleepRecord)
                        } header: {
                            HStack {
                                Text("スリープ")
                                
                                Spacer()
                                
                                if recordToRemove == sleepRecord {
                                    Button(role: .destructive) {
                                        record.sleepRecords.removeAll(where: { $0 == sleepRecord })
                                        recordToRemove = nil
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.red)
                                    }
                                    .accessibilityIdentifier("button_remove_sleep_record")
                                } else {
                                    Button {
                                        recordToRemove = sleepRecord
                                    } label: {
                                        Image(systemName: "minus")
                                    }
                                    .accessibilityIdentifier("button_remove_sleep_confirm")
                                }
                            }
                        }
                    }
                    
                    Button("スリープを追加", systemImage: "plus") {
                        let date = record.launch
                        let sleep = SystemUptimeRecord.SleepRecord(start: date, end: date)
                        record.sleepRecords.append(sleep)
                    }
                    .font(.footnote)
                    .accessibilityIdentifier("button_add_sleep_record")
                }
            }
        }
    }
    
    private struct SleepRecordView: View {
        @Bindable var sleepRecord: SystemUptimeRecord.SleepRecord
        
        var body: some View {
            Form {
                DatePicker("開始", selection: $sleepRecord.start, displayedComponents: [.date, .hourAndMinute])
                    .accessibilityIdentifier("date_sleep_start")
                DatePicker("終了", selection: $sleepRecord.end, displayedComponents: [.date, .hourAndMinute])
                    .accessibilityIdentifier("date_sleep_end")
            }
        }
    }
}

#Preview {
    @Previewable @State var record = CalendarRecord(
        date: .now,
        records: [],
        systemUptimeRecords: [
            SystemUptimeRecord(
                year: Date.now.year,
                month: Date.now.month,
                day: Date.now.day,
                launch: .now,
                shutdown: .now,
                sleepRecords: [
                    SystemUptimeRecord.SleepRecord(
                        start: .now,
                        end: .now
                    )
                ]
            )
        ]
    )
    SystemUptimeRecordEditView(record: $record)
}
