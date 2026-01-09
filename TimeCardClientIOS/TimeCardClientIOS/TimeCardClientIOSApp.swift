//
//  TimeCardClientIOSApp.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/29.
//

import SwiftData
import SwiftUI

struct TimeCardClientIOSApp: App {
    private let container: ModelContainer
    private let calendar: CalendarViewModel
    
    init() {
        let schema = Schema([LocalTimeRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            self.container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        let network = DefaultNetworkDataSource()
        let local = DefaultLocalDataSource(context: container.mainContext)
        let repository = DefaultCalendarRecordRepository(networkDataSource: network, localDataSource: local)
        self.calendar = CalendarViewModel(repository: repository)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(calendar: calendar)
        }
    }
}

struct UITestApp: App {
    private let formatter: DateFormatter
    @State private var now: Date
    @State private var record: CalendarRecord
    private let repositoryForDetailView: FakeCalendarRecordRepositoryForDetailView
    @StateObject private var calendarForDetailView: CalendarViewModel
    @StateObject private var toast = ToastViewModel()
    private let repositoryForContentView: FakeCalendarRecordRepositoryForContentView
    @StateObject private var calendarForContentView: CalendarViewModel
    
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
        
        let repositoryForDetailView = FakeCalendarRecordRepositoryForDetailView()
        let calendarForDetailView = StateObject(wrappedValue: CalendarViewModel(repository: repositoryForDetailView))
        
        let repositoryForContentView = FakeCalendarRecordRepositoryForContentView()
        let calendarForContentView = StateObject(wrappedValue: CalendarViewModel(repository: repositoryForContentView))
        
        self.repositoryForDetailView = repositoryForDetailView
        self._calendarForDetailView = calendarForDetailView
        
        self.repositoryForContentView = repositoryForContentView
        self._calendarForContentView = calendarForContentView
    }
    
    var body: some Scene {
        WindowGroup {
            if CommandLine.arguments.contains("MonthSelectorViewTests") {
                MonthSelectorView(now: $now)
            } else if CommandLine.arguments.contains("CalendarRecordViewTests") {
                CalendarRecordView(record: record)
            } else if CommandLine.arguments.contains("CalendarDetailViewTests") {
                NavigationStack {
                    Text(calendarForDetailView.records.count, format:.number)
                        .accessibilityIdentifier("calendar_count")
                    if !calendarForDetailView.records.isEmpty {
                        Text(calendarForDetailView.records[0].date, format: .dateTime.month().day())
                            .accessibilityIdentifier("calendar_date")
                        Text(calendarForDetailView.records[0].records.count, format: .number)
                            .accessibilityIdentifier("record_count")
                        Text(calendarForDetailView.records[0].records[0].checkIn ?? .now, format: .dateTime.hour().minute())
                            .accessibilityIdentifier("record_check_in")
                        Text(calendarForDetailView.records[0].records[0].checkOut ?? .now, format: .dateTime.hour().minute())
                            .accessibilityIdentifier("record_check_out")
                        Text(calendarForDetailView.records[0].records[0].breakTimes.count, format: .number)
                            .accessibilityIdentifier("break_time_count")
                    }
                    NavigationLink {
                        CalendarDetailView(record: record, model: calendarForDetailView)
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
            } else if CommandLine.arguments.contains("ContentViewTests") {
                ContentView(calendar: calendarForContentView)
            }
        }
    }
}

private class FakeCalendarRecordRepositoryForDetailView: CalendarRecordRepository {
    private var publish: (([CalendarRecord]) -> Void)?
    func getRecords(year: Int, month: Int) -> AsyncThrowingStream<[CalendarRecord], Error> {
        AsyncThrowingStream { continuation in
            publish = { records in
                continuation.yield(records)
            }
        }
    }
    
    func updateRecord(source: [CalendarRecord], record: CalendarRecord) async throws {
        publish?([record])
    }
}

private class FakeCalendarRecordRepositoryForContentView: CalendarRecordRepository {
    func getRecords(year: Int, month: Int) -> AsyncThrowingStream<[CalendarRecord], Error> {
        let date = Calendar.current.date(from: DateComponents(year: year, month: month)) ?? .now
        if year == Date.now.year && month == Date.now.month {
            return AsyncThrowingStream { continuation in
                Task {
                    try await Task.sleep(for: .seconds(3))
                    
                    let records = Calendar.current.datesOf(year: 2025, month: 12).map { date in
                        CalendarRecord(date: date, records: [])
                    }
                    continuation.yield(records)
                }
            }
        } else if date > .now {
            return AsyncThrowingStream { continuation in
                Task {
                    try await Task.sleep(for: .seconds(3))
                    
                    let records = Calendar.current.datesOf(year: 2026, month: 1).map { date in
                        CalendarRecord(date: date, records: [])
                    }
                    continuation.yield(records)
                }
            }
        } else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: NSError())
            }
        }
    }
    
    func updateRecord(source: [CalendarRecord], record: CalendarRecord) async throws {
    }
}
