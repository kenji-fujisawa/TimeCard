//
//  ContentView.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/29.
//

import SwiftUI

struct ContentView: View {
    let calendarViewModel: CalendarViewModel
    let loginViewModel: LoginViewModel
    @State private var toast = ToastViewModel()
    
    var body: some View {
        if loginViewModel.isLoggedIn {
            VStack {
                CalendarView(viewModel: calendarViewModel)
            }
            .padding()
            .overlay {
                ToastView(viewModel: toast)
            }
            .environment(toast)
        } else {
            LoginView(viewModel: loginViewModel)
        }
    }
}

#Preview {
    let calendarRepository = FakeCalendarRecordRepository()
    let calendarViewModel = CalendarViewModel(calendarRepository)
    let authRepository = FakeAuthRepository()
    let loginViewModel = LoginViewModel(authRepository)
    ContentView(calendarViewModel: calendarViewModel, loginViewModel: loginViewModel)
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
    
    func getRecord(year: Int, month: Int, day: Int) throws -> CalendarRecord {
        CalendarRecord(date: .now, records: [])
    }
    func updateRecord(_ record: CalendarRecord) async throws {}
}

private class FakeAuthRepository: AuthRepository {
    func register(mail: String, password: String) async throws {}
    func verify(mail: String, verifyCode: String) async throws {}
    func login(mail: String, password: String) async throws {}
    func refresh() async throws {}
    func isLoggedIn() -> Bool { true }
    func onLogout(_ callback: @escaping () -> Void) {}
    func getAccessToken() -> String { "" }
}
