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
    private let repository: CalendarRecordRepository
    @State private var viewModel: CalendarViewModel
    
    init() {
        let schema = Schema([LocalTimeRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            self.container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        guard let url = URL(string: "http://192.168.4.33:8080") else { fatalError() }
        let network = DefaultNetworkDataSource(url)
        let local = DefaultLocalDataSource(container.mainContext)
        self.repository = DefaultCalendarRecordRepository(network, local)
        self.viewModel = CalendarViewModel(repository)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .environment(\.calendarRecordRepository, repository)
        }
    }
}

extension EnvironmentValues {
    @Entry var calendarRecordRepository: CalendarRecordRepository = FakeCalendarRecordRepository()
}

private class FakeCalendarRecordRepository: CalendarRecordRepository {
    func getRecordsStream(year: Int, month: Int) -> AsyncThrowingStream<[CalendarRecord], any Error> {
        AsyncThrowingStream { _ in }
    }
    func getRecord(year: Int, month: Int, day: Int) throws -> CalendarRecord {
        CalendarRecord(date: .now, records: [])
    }
    func updateRecord(_ record: CalendarRecord) async throws {}
}

#if DEBUG
struct UITestApp: App {
    private let formatter: DateFormatter
    @State private var date: Date
    @State private var record: CalendarRecord
    private let repositoryForDetailView: FakeCalendarRecordRepositoryForDetailView
    @State private var calendarForDetailView: CalendarViewModel
    @State private var toast = ToastViewModel()
    private let repositoryForContentView: FakeCalendarRecordRepositoryForContentView
    @State private var calendarForContentView: CalendarViewModel
    
    init() {
        formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        date = formatter.date(from: "2025-12-29 00:00:00") ?? .now
        
        record = CalendarRecord(
            date: formatter.date(from: "2025-12-29 00:00:00") ?? .now,
            records: [
                TimeRecord(
                    id: UUID(),
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
        
        self.repositoryForDetailView = FakeCalendarRecordRepositoryForDetailView()
        self.calendarForDetailView = CalendarViewModel(repositoryForDetailView)
        
        self.repositoryForContentView = FakeCalendarRecordRepositoryForContentView()
        self.calendarForContentView = CalendarViewModel(repositoryForContentView)
    }
    
    var body: some Scene {
        WindowGroup {
            if CommandLine.arguments.contains("MonthSelectorViewTests") {
                MonthSelectorView(date: $date)
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
                        CalendarDetailView(viewModel: CalendarDetailViewModel(repositoryForDetailView, date))
                            .environment(toast)
                    } label: {
                        Text("link")
                    }
                }
            } else if CommandLine.arguments.contains("ToastViewTests") {
                ToastView(viewModel: toast)
                Button("show") {
                    toast.message = "test message"
                    toast.isPresented = true
                }
                .accessibilityIdentifier("button_show_toast")
            } else if CommandLine.arguments.contains("ContentViewTests") {
                ContentView(viewModel: calendarForContentView)
            }
        }
    }
}

private class FakeCalendarRecordRepositoryForDetailView: CalendarRecordRepository {
    private var publish: (([CalendarRecord]) -> Void)?
    func getRecordsStream(year: Int, month: Int) -> AsyncThrowingStream<[CalendarRecord], Error> {
        AsyncThrowingStream { continuation in
            publish = { records in
                continuation.yield(records)
            }
        }
    }
    
    func getRecord(year: Int, month: Int, day: Int) throws -> CalendarRecord {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        return CalendarRecord(
            date: formatter.date(from: "2025-12-29 00:00:00") ?? .now,
            records: [
                TimeRecord(
                    id: UUID(),
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
    }
    
    func updateRecord(_ record: CalendarRecord) async throws {
        publish?([record])
    }
}

private class FakeCalendarRecordRepositoryForContentView: CalendarRecordRepository {
    func getRecordsStream(year: Int, month: Int) -> AsyncThrowingStream<[CalendarRecord], Error> {
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
    
    func getRecord(year: Int, month: Int, day: Int) throws -> CalendarRecord {
        CalendarRecord(date: .now, records: [])
    }
    func updateRecord(_ record: CalendarRecord) async throws {}
}
#endif
