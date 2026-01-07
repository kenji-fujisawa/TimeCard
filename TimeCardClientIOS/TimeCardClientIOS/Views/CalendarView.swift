//
//  CalendarView.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/29.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var toast: ToastViewModel
    @ObservedObject var model: CalendarViewModel
    
    var body: some View {
        NavigationStack {
            if model.loading {
                ProgressView()
            } else {
                MonthSelectorView(now: $model.now)
                    .onChange(of: model.now) { _, _ in
                        withAnimation {
                            model.fetchRecords()
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
                        
                        ForEach(model.records) { record in
                            NavigationLink {
                                CalendarDetailView(record: record, model: model)
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
        .onChange(of: model.message) { _, _ in
            if !model.message.isEmpty {
                withAnimation {
                    toast.isPresented = true
                    toast.message = model.message
                    model.message = ""
                }
            }
        }
    }
}

#Preview {
    let repository = FakeCalendarRecordRepository()
    let model = CalendarViewModel(repository: repository)
    CalendarView(model: model)
        .environmentObject(ToastViewModel())
}

private class FakeCalendarRecordRepository: CalendarRecordRepository {
    func getRecords(year: Int, month: Int) async throws -> [CalendarRecord] {
        Calendar.current.datesOf(year: year, month: month).map { date in
            CalendarRecord(date: date, records: [])
        }
    }
    
    func updateRecord(source: [CalendarRecord], record: CalendarRecord) async throws -> [CalendarRecord] {
        []
    }
}
