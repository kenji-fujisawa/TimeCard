//
//  TimeRecordEditView.swift
//  TimeCard
//
//  Created by uhimania on 2025/12/08.
//

import SwiftUI

struct TimeRecordEditView: View {
    @Bindable var viewModel: TimeRecordEditViewModel
    @State private var selectedId: TimeRecordEditViewModel.TimeRecord.ID? = nil
    
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
        var viewModel: TimeRecordEditViewModel
        @Binding var selectedId: TimeRecordEditViewModel.TimeRecord.ID?
        @State private var recordToRemove: TimeRecordEditViewModel.TimeRecord? = nil
        
        var body: some View {
            List(selection: $selectedId) {
                Section("出勤時刻") {
                    ForEach(viewModel.records) { record in
                        HStack {
                            Text(record.checkIn.formatted(.dateTime.hour().minute()))
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
                
                Button("追加", systemImage: "plus") {
                    addRecord()
                }
                .font(.footnote)
                .accessibilityIdentifier("button_add_time_record")
            }
        }
        
        private func addRecord() {
            let date = viewModel.date
            let record = TimeRecordEditViewModel.TimeRecord(checkIn: date, checkOut: date)
            viewModel.records.append(record)
            selectedId = record.id
        }
        
        private func removeRecord(record: TimeRecordEditViewModel.TimeRecord) {
            viewModel.records.removeAll(where: { $0 == record })
            recordToRemove = nil
            if selectedId == record.id {
                selectedId = viewModel.records.first?.id
            }
        }
    }
    
    private struct DetailView: View {
        @Bindable var record: TimeRecordEditViewModel.TimeRecord
        @State private var recordToRemove: TimeRecordEditViewModel.TimeRecord.BreakTime? = nil
        
        var body: some View {
            VStack(alignment: .leading) {
                Form {
                    DatePicker("出勤", selection: $record.checkIn, displayedComponents: [.date, .hourAndMinute])
                        .accessibilityIdentifier("date_check_in")
                    DatePicker("退勤", selection: $record.checkOut, displayedComponents: [.date, .hourAndMinute])
                        .accessibilityIdentifier("date_check_out")
                }
                .padding()
                
                List {
                    ForEach(record.breakTimes) { breakTime in
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
                        let breakTime = TimeRecordEditViewModel.TimeRecord.BreakTime(start: date, end: date)
                        record.breakTimes.append(breakTime)
                    }
                    .font(.footnote)
                    .accessibilityIdentifier("button_add_break_time")
                }
            }
        }
    }
    
    private struct BreakTimeView: View {
        @Bindable var breakTime: TimeRecordEditViewModel.TimeRecord.BreakTime
        
        var body: some View {
            Form {
                DatePicker("開始", selection: $breakTime.start, displayedComponents: [.date, .hourAndMinute])
                    .accessibilityIdentifier("date_break_start")
                DatePicker("終了", selection: $breakTime.end, displayedComponents: [.date, .hourAndMinute])
                    .accessibilityIdentifier("date_break_end")
            }
        }
    }
}

#Preview {
    let viewModel = TimeRecordEditViewModel(
        date: .now,
        records: [
            TimeRecordEditViewModel.TimeRecord(
                checkIn: .now,
                checkOut: .now,
                breakTimes: [
                    TimeRecordEditViewModel.TimeRecord.BreakTime(
                        start: .now,
                        end: .now
                    ),
                    TimeRecordEditViewModel.TimeRecord.BreakTime(
                        start: .now,
                        end: .now
                    )
                ]
            ),
            TimeRecordEditViewModel.TimeRecord(
                checkIn: .now,
                checkOut: .now,
                breakTimes: [
                    TimeRecordEditViewModel.TimeRecord.BreakTime(
                        start: .now,
                        end: .now
                    )
                ]
            )
        ]
    )
    TimeRecordEditView(viewModel: viewModel)
}
