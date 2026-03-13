//
//  ContentView.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/29.
//

import SwiftUI

struct ContentView: View {
    let viewModel: CalendarViewModel
    @State private var toast = ToastViewModel()
    
    var body: some View {
        VStack {
            CalendarView(viewModel: viewModel)
        }
        .padding()
        .overlay {
            ToastView(viewModel: toast)
        }
        .environment(toast)
    }
}

#Preview {
    let repository = FakeCalendarRecordRepository()
    let viewModel = CalendarViewModel(repository)
    ContentView(viewModel: viewModel)
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
