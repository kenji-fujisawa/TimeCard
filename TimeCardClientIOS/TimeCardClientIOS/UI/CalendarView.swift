//
//  CalendarView.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/29.
//

import SwiftUI

struct CalendarView: View {
    @Environment(ToastViewModel.self) private var toast: ToastViewModel
    @Bindable var viewModel: CalendarViewModel
    
    var body: some View {
        NavigationStack {
            if viewModel.loading {
                ProgressView()
            } else {
                MonthSelectorView(date: $viewModel.date)
                    .onChange(of: viewModel.date) { _, _ in
                        withAnimation {
                            viewModel.fetchRecords()
                        }
                    }
                
                ScrollView {
                    Grid {
                        GridRow {
                            Text("")
                            Text("出勤")
                            Text("退勤")
                            Text("休始")
                            Text("休終")
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                        
                        ForEach(viewModel.records) { record in
                            NavigationLink {
                                CalendarDetailView(record: record, viewModel: viewModel)
                            } label: {
                                CalendarRecordView(record: record)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                        }
                    }
                }
                .padding()
            }
        }
        .onChange(of: viewModel.message) { _, _ in
            if !viewModel.message.isEmpty {
                withAnimation {
                    toast.isPresented = true
                    toast.message = viewModel.message
                    viewModel.message = ""
                }
            }
        }
    }
}

#Preview {
    let repository = FakeCalendarRecordRepository()
    let viewModel = CalendarViewModel(repository)
    CalendarView(viewModel: viewModel)
        .environment(ToastViewModel())
}

private class FakeCalendarRecordRepository: CalendarRecordRepository {
    func getRecordsStream(year: Int, month: Int) -> AsyncThrowingStream<[CalendarRecord], Error> {
        AsyncThrowingStream { continuation in
            let records = Calendar.current.datesOf(year: year, month: month).map { date in
                CalendarRecord(date: date, records: [])
            }
            continuation.yield(records)
        }
    }
    
    func updateRecord(_ record: CalendarRecord) async throws {}
}
