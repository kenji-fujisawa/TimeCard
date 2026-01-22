//
//  ContentView.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/29.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @StateObject var calendar: CalendarViewModel
    @StateObject private var toast = ToastViewModel()
    
    var body: some View {
        VStack {
            CalendarView(model: calendar)
        }
        .padding()
        .overlay {
            ToastView(model: toast)
        }
        .environmentObject(toast)
    }
}

#Preview {
    let repository = FakeCalendarRecordRepository()
    let calendar = CalendarViewModel(repository: repository)
    ContentView(calendar: calendar)
}

private class FakeCalendarRecordRepository: CalendarRecordRepository {
    func getRecords(year: Int, month: Int) -> AsyncThrowingStream<[CalendarRecord], Error> {
        AsyncThrowingStream { continuation in
            let records = Calendar.current.datesOf(year: year, month: month).map { date in
                CalendarRecord(date: date, records: [])
            }
            continuation.yield(records)
        }
    }
    
    func updateRecord(source: [CalendarRecord], record: CalendarRecord) async throws {
    }
}
