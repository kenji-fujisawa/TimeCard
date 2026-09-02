//
//  TimeCardClientIOSApp.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/29.
//

import SwiftData
import SwiftUI

enum Constants {
    static let accessTokenKey = "jp.uhimania.TimeCardClient.AccessToken"
    static let refreshTokenKey = "jp.uhimania.TimeCardClient.RefreshToken"
}

struct TimeCardClientIOSApp: App {
    private let container: ModelContainer
    private let repository: CalendarRecordRepository
    @State private var calendarViewModel: CalendarViewModel
    @State private var loginViewModel: LoginViewModel
    
    init() {
        let schema = Schema([LocalTimeRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            self.container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        guard let url = URL(string: "http://192.168.4.33:8080") else { fatalError() }
        let auth = DefaultAuthNetworkDataSource(url)
        let secure = KeyChainDataSource()
        let authRepository = DefaultAuthRepository(auth, secure)
        let session = DefaultAuthURLSession(authRepository)
        let network = DefaultNetworkDataSource(url, session)
        let local = DefaultLocalDataSource(container.mainContext)
        self.repository = DefaultCalendarRecordRepository(network, local)
        self.calendarViewModel = CalendarViewModel(repository)
        self.loginViewModel = LoginViewModel(authRepository)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(calendarViewModel: calendarViewModel, loginViewModel: loginViewModel)
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
    private let container: ModelContainer
    private let calendarRepository: CalendarRecordRepository
    private let authRepository: AuthRepository
    @State private var date: Date
    @State private var record: CalendarRecord
    @State private var toast = ToastViewModel()
    @State private var login: LoginViewModel
    @State private var text: String = ""
    
    init() {
        let schema = Schema([LocalTimeRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            self.container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        let network = FakeNetworkDataSource()
        let local = DefaultLocalDataSource(container.mainContext)
        calendarRepository = DefaultCalendarRecordRepository(network, local)
        
        authRepository = LoginAuthRepository()
        login = LoginViewModel(authRepository)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        date = formatter.date(from: "2025-12-29 00:00:00") ?? .now
        
        record = CalendarRecord(
            date: formatter.date(from: "2025-12-29 00:00:00") ?? .now,
            records: [
                TimeRecord(
                    id: UUID(),
                    checkIn: formatter.date(from: "2025-12-29 10:12:38"),
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
        
        record.records.forEach { try? local.insertRecord($0) }
    }
    
    var body: some Scene {
        WindowGroup {
            if CommandLine.arguments.contains("MonthSelectorViewTests") {
                MonthSelectorView(date: $date)
            } else if CommandLine.arguments.contains("CalendarRecordViewTests") {
                CalendarRecordView(record: record.asViewModel())
            } else if CommandLine.arguments.contains("CalendarDetailViewTests") {
                NavigationStack {
                    Text(record.date, format: .dateTime.month().day())
                        .accessibilityIdentifier("calendar_date")
                    Text(record.records.count, format: .number)
                        .accessibilityIdentifier("record_count")
                    Text(record.records[0].checkIn ?? .now, format: .dateTime.hour().minute())
                        .accessibilityIdentifier("record_check_in")
                    Text(record.records[0].checkOut ?? .now, format: .dateTime.hour().minute())
                        .accessibilityIdentifier("record_check_out")
                    Text(record.records[0].breakTimes.count, format: .number)
                        .accessibilityIdentifier("break_time_count")
                    NavigationLink {
                        CalendarDetailView(repository: calendarRepository, date: date)
                            .environment(toast)
                    } label: {
                        Text("link")
                    }
                    Button("update") {
                        if let record = try? calendarRepository.getRecord(year: date.year, month: date.month, day: date.day) {
                            self.record = record
                        }
                    }
                }
            } else if CommandLine.arguments.contains("ToastViewTests") {
                ToastView(viewModel: toast)
                Button("show") {
                    toast.message = "test message"
                    toast.isPresented = true
                }
            } else if CommandLine.arguments.contains("ContentViewTests") {
                if CommandLine.arguments.contains("testLoading") {
                    ContentView(calendarViewModel: CalendarViewModel(LoadingCalendarRecordRepository()), loginViewModel: LoginViewModel(ContentAuthRepository()))
                } else if CommandLine.arguments.contains("testToast") {
                    ContentView(calendarViewModel: CalendarViewModel(ToastCalendarRecordRepository()), loginViewModel: LoginViewModel(ContentAuthRepository()))
                } else if CommandLine.arguments.contains("testLogin") {
                    ContentView(calendarViewModel: CalendarViewModel(ToastCalendarRecordRepository()), loginViewModel: LoginViewModel(LoginAuthRepository()))
                }
            } else if CommandLine.arguments.contains("LoginViewTests") {
                LoginView(viewModel: login)
                Text(text)
                    .accessibilityIdentifier("text_login")
                Button("update") {
                    text = authRepository.isLoggedIn() ? "logged in" : "logged out"
                }
            }
        }
    }
}

private class FakeNetworkDataSource: NetworkDataSource {
    func getRecords(year: Int, month: Int) async throws -> [TimeRecord] { [] }
    func insertRecord(_ record: TimeRecord) async throws -> TimeRecord { record }
    func updateRecord(_ record: TimeRecord) async throws -> TimeRecord { record }
    func deleteRecord(_ record: TimeRecord) async throws {}
}

private class LoadingCalendarRecordRepository: CalendarRecordRepository {
    private static var year = 2025
    private static var month = 12
    func getRecordsStream(year: Int, month: Int) -> AsyncThrowingStream<[CalendarRecord], any Error> {
        AsyncThrowingStream { continuation in
            Task {
                try await Task.sleep(for: .seconds(3))
                
                let records = Calendar.current.datesOf(year: LoadingCalendarRecordRepository.year, month: LoadingCalendarRecordRepository.month).map { date in
                    CalendarRecord(date: date, records: [])
                }
                continuation.yield(records)
                
                LoadingCalendarRecordRepository.year = 2026
                LoadingCalendarRecordRepository.month = 1
            }
        }
    }
    
    func getRecord(year: Int, month: Int, day: Int) throws -> CalendarRecord {
        CalendarRecord(date: .now, records: [])
    }
    func updateRecord(_ record: CalendarRecord) async throws {}
}

private class ToastCalendarRecordRepository: CalendarRecordRepository {
    func getRecordsStream(year: Int, month: Int) -> AsyncThrowingStream<[CalendarRecord], any Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: NSError())
        }
    }
    
    func getRecord(year: Int, month: Int, day: Int) throws -> CalendarRecord {
        CalendarRecord(date: .now, records: [])
    }
    func updateRecord(_ record: CalendarRecord) async throws {}
}

private class ContentAuthRepository: AuthRepository {
    func register(mail: String, password: String) async throws {}
    func verify(mail: String, verifyCode: String) async throws {}
    func login(mail: String, password: String) async throws {}
    func refresh() async throws {}
    func isLoggedIn() -> Bool { true }
    func onLogout(_ callback: @escaping () -> Void) {}
    func getAccessToken() -> String { "" }
}

private class LoginAuthRepository: AuthRepository {
    func register(mail: String, password: String) async throws {}
    
    var loggedIn = false
    func verify(mail: String, verifyCode: String) async throws {
        loggedIn = true
    }
    
    func login(mail: String, password: String) async throws {
        loggedIn = true
    }
    
    func refresh() async throws {}
    func isLoggedIn() -> Bool { loggedIn }
    func onLogout(_ callback: @escaping () -> Void) {}
    func getAccessToken() -> String { "" }
}
#endif
