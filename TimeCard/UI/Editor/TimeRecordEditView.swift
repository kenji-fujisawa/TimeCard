//
//  TimeRecordEditView.swift
//  TimeCard
//
//  Created by uhimania on 2025/12/08.
//

import SwiftUI

struct TimeRecordEditView: View {
    @Bindable var viewModel: TimeRecordEditViewModel
    
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
        @Bindable var viewModel: TimeRecordEditViewModel
        
        var body: some View {
            List(selection: $viewModel.selectedId) {
                Section("出勤時刻") {
                    ForEach(viewModel.records) { record in
                        HStack {
                            Text(record.checkIn.formatted(.dateTime.hour().minute()))
                                .accessibilityIdentifier("nav_link")
                            
                            Spacer()
                            
                            if viewModel.removeId == record.id {
                                Button(role: .destructive) {
                                    viewModel.removeRecord()
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .accessibilityIdentifier("button_remove_time_record")
                            } else {
                                Button {
                                    viewModel.removeId = record.id
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
                    viewModel.addRecord()
                }
                .font(.footnote)
                .accessibilityIdentifier("button_add_time_record")
            }
        }
    }
    
    private struct DetailView: View {
        @Bindable var record: TimeRecordEditViewModel.TimeRecord
        
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
                                
                                if record.removeId == breakTime.id {
                                    Button(role: .destructive) {
                                        record.removeBreakTime()
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.red)
                                    }
                                    .accessibilityIdentifier("button_remove_break_time")
                                } else {
                                    Button {
                                        record.removeId = breakTime.id
                                    } label: {
                                        Image(systemName: "minus")
                                    }
                                    .accessibilityIdentifier("button_remove_break_confirm")
                                }
                            }
                        }
                    }
                    
                    Button("休憩を追加", systemImage: "plus") {
                        record.addBreakTime()
                    }
                    .font(.footnote)
                    .accessibilityIdentifier("button_add_break_time")
                }
            }
        }
    }
    
    private struct BreakTimeView: View {
        @Bindable var breakTime: TimeRecordEditViewModel.BreakTime
        
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
                    TimeRecordEditViewModel.BreakTime(
                        start: .now,
                        end: .now
                    ),
                    TimeRecordEditViewModel.BreakTime(
                        start: .now,
                        end: .now
                    )
                ]
            ),
            TimeRecordEditViewModel.TimeRecord(
                checkIn: .now,
                checkOut: .now,
                breakTimes: [
                    TimeRecordEditViewModel.BreakTime(
                        start: .now,
                        end: .now
                    )
                ]
            )
        ]
    )
    TimeRecordEditView(viewModel: viewModel)
}
