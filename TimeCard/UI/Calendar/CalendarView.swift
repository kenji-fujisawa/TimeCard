//
//  CalendarView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/02.
//

import SwiftUI

struct CalendarView: View {
    @Bindable var viewModel: CalendarViewModel
    
    var body: some View {
        VStack {
            MonthSelectorView(date: $viewModel.date)
                .onChange(of: viewModel.date) { _, _ in
                    viewModel.fetchRecords()
                }
            
            CalendarBodyView(viewModel: viewModel)
        }
        .padding()
        .toolbar {
            ExportPDFView()
        }
    }
}

#Preview {
    let repository = FakeCalendarRecordRepository()
    let viewModel = CalendarViewModel(repository)
    CalendarView(viewModel: viewModel)
}

private class FakeCalendarRecordRepository: CalendarRecordRepository {
    func getRecordsStream(year: Int, month: Int) -> AsyncStream<[CalendarRecord]> {
        AsyncStream { continuation in
            let records = Calendar.current.datesOf(year: year, month: month).map { date in
                CalendarRecord(date: date, timeRecords: [], uptimeRecords: [])
            }
            continuation.yield(records)
        }
    }
    
    func updateRecord(_ record: CalendarRecord) throws {}
}
