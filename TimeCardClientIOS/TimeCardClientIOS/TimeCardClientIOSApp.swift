//
//  TimeCardClientIOSApp.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/29.
//

import SwiftUI

struct TimeCardClientIOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct UITestApp: App {
    private let formatter: DateFormatter
    @State private var now: Date
    @State private var record: CalendarRecord
    private let repository: FakeCalendarRecordRepository
    @ObservedObject private var calendar: CalendarViewModel
    @StateObject private var toast = ToastViewModel()
    
    init() {
        formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        now = formatter.date(from: "2025-12-29 00:00:00") ?? .now
        
        record = CalendarRecord(
            date: formatter.date(from: "2025-12-29 00:00:00") ?? .now,
            records: [
                TimeRecord(
                    id: UUID(),
                    year: 2025,
                    month: 12,
                    checkIn: formatter.date(from: "2025-12-29 09:12:38"),
                    checkOut: formatter.date(from: "2025-12-30 02:28:11"),
                    breakTimes: [
                        TimeRecord.BreakTime(
                            id: UUID(),
                            start: formatter.date(from: "2025-12-29 23:45:58"),
                            end: formatter.date(from: "2025-12-30 01:30:45")
                        )
                    ]
                )
            ]
        )
        
        repository = FakeCalendarRecordRepository()
        calendar = CalendarViewModel(repository: repository)
    }
    
    var body: some Scene {
        WindowGroup {
            if CommandLine.arguments.contains("MonthSelectorViewTests") {
                MonthSelectorView(now: $now)
            } else if CommandLine.arguments.contains("CalendarRecordViewTests") {
                CalendarRecordView(record: record)
            } else if CommandLine.arguments.contains("CalendarDetailViewTests") {
                NavigationStack {
                    Text(calendar.records.count, format:.number)
                        .accessibilityIdentifier("calendar_count")
                    if !calendar.records.isEmpty {
                        Text(calendar.records[0].date, format: .dateTime.month().day())
                            .accessibilityIdentifier("calendar_date")
                        Text(calendar.records[0].records.count, format: .number)
                            .accessibilityIdentifier("record_count")
                        Text(calendar.records[0].records[0].checkIn ?? .now, format: .dateTime.hour().minute())
                            .accessibilityIdentifier("record_check_in")
                        Text(calendar.records[0].records[0].checkOut ?? .now, format: .dateTime.hour().minute())
                            .accessibilityIdentifier("record_check_out")
                        Text(calendar.records[0].records[0].breakTimes.count, format: .number)
                            .accessibilityIdentifier("break_time_count")
                    }
                    NavigationLink {
                        CalendarDetailView(record: record, model: calendar)
                    } label: {
                        Text("link")
                    }
                }
            } else if CommandLine.arguments.contains("ToastViewTests") {
                ToastView(model: toast)
                Button("show") {
                    toast.message = "test message"
                    toast.isPresented = true
                }
                .accessibilityIdentifier("button_show_toast")
            }
        }
    }
}

private class FakeCalendarRecordRepository: CalendarRecordRepository {
    func getRecords(year: Int, month: Int) async throws -> [CalendarRecord] {
        []
    }
    
    func updateRecord(source: [CalendarRecord], record: CalendarRecord) async throws -> [CalendarRecord] {
        [record]
    }
}
