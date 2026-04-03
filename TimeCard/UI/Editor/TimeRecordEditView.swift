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
                let record = viewModel.records[index]
                DetailView(record: record, valid: viewModel.isValid(record))
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
                                .foregroundStyle(!viewModel.isValid(record) ? .red : .primary)
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
        let valid: Bool
        
        var body: some View {
            VStack(alignment: .leading) {
                Form {
                    DatePicker("出勤", selection: $record.checkIn, displayedComponents: [.date, .hourAndMinute])
                        .isValid(valid)
                        .accessibilityIdentifier("date_check_in")
                    DatePicker("退勤", selection: $record.checkOut, displayedComponents: [.date, .hourAndMinute])
                        .isValid(valid)
                        .accessibilityIdentifier("date_check_out")
                }
                .padding()
                .disabled(!record.editable)
                
                List {
                    ForEach(record.breakTimes) { breakTime in
                        Section {
                            BreakTimeView(breakTime: breakTime, valid: record.isValid(breakTime))
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
                        .disabled(!record.editable)
                    }
                    
                    Button("休憩を追加", systemImage: "plus") {
                        record.addBreakTime()
                    }
                    .font(.footnote)
                    .disabled(!record.editable)
                    .accessibilityIdentifier("button_add_break_time")
                }
            }
        }
    }
    
    private struct BreakTimeView: View {
        @Bindable var breakTime: TimeRecordEditViewModel.BreakTime
        let valid: Bool
        
        var body: some View {
            Form {
                DatePicker("開始", selection: $breakTime.start, displayedComponents: [.date, .hourAndMinute])
                    .isValid(valid)
                    .accessibilityIdentifier("date_break_start")
                DatePicker("終了", selection: $breakTime.end, displayedComponents: [.date, .hourAndMinute])
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
            content
                .padding(2)
                .border(.red)
        }
    }
}

private extension View {
    func isValid(_ valid: Bool) -> some View {
        self.modifier(ValidModifier(valid: valid))
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
