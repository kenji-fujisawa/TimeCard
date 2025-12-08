//
//  TimeRecordEditView.swift
//  TimeCard
//
//  Created by uhimania on 2025/12/08.
//

import SwiftUI

struct TimeRecordEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State var record: CalendarRecord
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
                                
                                Spacer()
                                
                                if recordToRemove == record {
                                    Button(role: .destructive) {
                                        removeRecord(record: record)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.red)
                                    }
                                } else {
                                    Button {
                                        recordToRemove = record
                                    } label: {
                                        Image(systemName: "minus")
                                    }
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
                    DatePicker("退勤", selection: $record.checkOut.bindUnwrap(defaultValue: .now), displayedComponents: [.date, .hourAndMinute])
                }
                .padding()
                
                List {
                    ForEach(record.sortedBreakTimes) { breakTime in
                        BreakTimeView(record: record, breakTime: breakTime, recordToRemove: $recordToRemove)
                    }
                    
                    Button("休憩を追加", systemImage: "plus") {
                        let date = record.checkIn
                        let breakTime = TimeRecord.BreakTime(start: date, end: date)
                        record.breakTimes.append(breakTime)
                    }
                    .font(.footnote)
                }
            }
        }
    }
    
    private struct BreakTimeView: View {
        @Bindable var record: TimeRecord
        @Bindable var breakTime: TimeRecord.BreakTime
        @Binding var recordToRemove: TimeRecord.BreakTime?
        
        var body: some View {
            Section {
                Form {
                    DatePicker("開始", selection: $breakTime.start.bindUnwrap(defaultValue: .now), displayedComponents: [.date, .hourAndMinute])
                    DatePicker("終了", selection: $breakTime.end.bindUnwrap(defaultValue: .now), displayedComponents: [.date, .hourAndMinute])
                }
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
                    } else {
                        Button {
                            recordToRemove = breakTime
                        } label: {
                            Image(systemName: "minus")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let break1 = TimeRecord.BreakTime(start: .now, end: .now)
    let break2 = TimeRecord.BreakTime(start: .now)
    let rec1 = TimeRecord(year: Date.now.year, month: Date.now.month, checkIn: .now, checkOut: .now, breakTimes: [break1, break2])
    let rec2 = TimeRecord(year: Date.now.year, month: Date.now.month, checkIn: .now, breakTimes: [break1])
    let uptime = SystemUptimeRecord(year: Date.now.year, month: Date.now.month, day: Date.now.day, launch: Date.now, shutdown: Date.now)
    let record = CalendarRecord(date: .now, records: [rec1, rec2], systemUptimeRecords: [uptime])
    TimeRecordEditView(record: record)
}
