//
//  CalendarView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/02.
//

import SwiftUI

struct CalendarView: View {
    @ObservedObject var calendar: CalendarViewModel
    
    var body: some View {
        VStack {
            MonthSelectorView(now: $calendar.now)
                .onChange(of: calendar.now) { _, _ in
                    calendar.fetchRecords()
                }
            
            CalendarBodyView(calendar: calendar)
        }
        .padding()
        .toolbar {
            ExportPDFView()
        }
    }
}

#Preview {
    let repository = FakeCalendarRecordRepository()
    let calendar = CalendarViewModel(repository: repository)
    CalendarView(calendar: calendar)
}

private class FakeCalendarRecordRepository: CalendarRecordRepository {
    func getRecords(year: Int, month: Int) -> AsyncStream<[CalendarRecord]> {
        AsyncStream { continuation in
            let records = Calendar.current.datesOf(year: year, month: month).map { date in
                CalendarRecord(date: date, records: [], systemUptimeRecords: [])
            }
            continuation.yield(records)
        }
    }
    
    func updateRecord(source: [CalendarRecord], record: CalendarRecord) throws {}
}
