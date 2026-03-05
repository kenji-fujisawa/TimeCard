//
//  SystemUptimeRecordEditView.swift
//  TimeCard
//
//  Created by uhimania on 2025/12/08.
//

import SwiftUI

struct SystemUptimeRecordEditView: View {
    @Bindable var viewModel: UptimeRecordEditViewModel
    @State private var selectedId: UptimeRecordEditViewModel.SystemUptimeRecord.ID? = nil
    
    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel, selectedId: $selectedId)
        } detail: {
            if let index = viewModel.records.firstIndex(where: { $0.id == selectedId }) {
                DetailView(record: viewModel.records[index])
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .onAppear() {
            selectedId = viewModel.records.first?.id
        }
    }
    
    private struct SidebarView: View {
        var viewModel: UptimeRecordEditViewModel
        @Binding var selectedId: UptimeRecordEditViewModel.SystemUptimeRecord.ID?
        @State private var recordToRemove: UptimeRecordEditViewModel.SystemUptimeRecord? = nil
        
        var body: some View {
            List(selection: $selectedId) {
                Section("稼働時間") {
                    ForEach(viewModel.records) { record in
                        HStack {
                            Text(record.uptime.formatted(.timeWorked))
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
                        .tag(record.id)
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
            let date = viewModel.date
            let record = UptimeRecordEditViewModel.SystemUptimeRecord(launch: date, shutdown: date)
            viewModel.records.append(record)
            selectedId = record.id
        }
        
        private func removeRecord(record: UptimeRecordEditViewModel.SystemUptimeRecord) {
            viewModel.records.removeAll(where: { $0 == record })
            recordToRemove = nil
            if selectedId == record.id {
                selectedId = viewModel.records.first?.id
            }
        }
    }
    
    private struct DetailView: View {
        @Bindable var record: UptimeRecordEditViewModel.SystemUptimeRecord
        @State private var recordToRemove: UptimeRecordEditViewModel.SystemUptimeRecord.SleepRecord? = nil
        
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
                    ForEach(record.sleepRecords) { sleepRecord in
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
                        let sleep = UptimeRecordEditViewModel.SystemUptimeRecord.SleepRecord(start: date, end: date)
                        record.sleepRecords.append(sleep)
                    }
                    .font(.footnote)
                    .accessibilityIdentifier("button_add_sleep_record")
                }
            }
        }
    }
    
    private struct SleepRecordView: View {
        @Bindable var sleepRecord: UptimeRecordEditViewModel.SystemUptimeRecord.SleepRecord
        
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
    let viewModel = UptimeRecordEditViewModel(
        date: .now,
        records: [
            UptimeRecordEditViewModel.SystemUptimeRecord(
                launch: .now,
                shutdown: .now,
                sleepRecords: [
                    UptimeRecordEditViewModel.SystemUptimeRecord.SleepRecord(
                        start: .now,
                        end: .now
                    )
                ]
            )
        ]
    )
    SystemUptimeRecordEditView(viewModel: viewModel)
}
