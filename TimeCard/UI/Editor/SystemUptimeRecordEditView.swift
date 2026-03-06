//
//  SystemUptimeRecordEditView.swift
//  TimeCard
//
//  Created by uhimania on 2025/12/08.
//

import SwiftUI

struct SystemUptimeRecordEditView: View {
    @Bindable var viewModel: UptimeRecordEditViewModel
    
    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
        } detail: {
            if let index = viewModel.records.firstIndex(where: { $0.id == viewModel.selectedId }) {
                DetailView(record: viewModel.records[index])
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private struct SidebarView: View {
        @Bindable var viewModel: UptimeRecordEditViewModel
        
        var body: some View {
            List(selection: $viewModel.selectedId) {
                Section("稼働時間") {
                    ForEach(viewModel.records) { record in
                        HStack {
                            Text(record.uptime.formatted(.timeWorked))
                            .accessibilityIdentifier("nav_link")
                            
                            Spacer()
                            
                            if viewModel.removeId == record.id {
                                Button(role: .destructive) {
                                    viewModel.removeRecord()
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .accessibilityIdentifier("button_remove_uptime_record")
                            } else {
                                Button {
                                    viewModel.removeId = record.id
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
                    viewModel.addRecord()
                }
                .font(.footnote)
                .accessibilityIdentifier("button_add_uptime_record")
            }
        }
    }
    
    private struct DetailView: View {
        @Bindable var record: UptimeRecordEditViewModel.SystemUptimeRecord
        
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
                                
                                if record.removeId == sleepRecord.id {
                                    Button(role: .destructive) {
                                        record.removeSleep()
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.red)
                                    }
                                    .accessibilityIdentifier("button_remove_sleep_record")
                                } else {
                                    Button {
                                        record.removeId = sleepRecord.id
                                    } label: {
                                        Image(systemName: "minus")
                                    }
                                    .accessibilityIdentifier("button_remove_sleep_confirm")
                                }
                            }
                        }
                    }
                    
                    Button("スリープを追加", systemImage: "plus") {
                        record.addSleep()
                    }
                    .font(.footnote)
                    .accessibilityIdentifier("button_add_sleep_record")
                }
            }
        }
    }
    
    private struct SleepRecordView: View {
        @Bindable var sleepRecord: UptimeRecordEditViewModel.SleepRecord
        
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
                    UptimeRecordEditViewModel.SleepRecord(
                        start: .now,
                        end: .now
                    )
                ]
            )
        ]
    )
    SystemUptimeRecordEditView(viewModel: viewModel)
}
