//
//  ServerView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/28.
//

import SwiftUI

struct ServerView: View {
    @Environment(\.terminationManager) private var terminationManager
    let server: TimeCardServer
    @State private var becomeActive = false
    
    var body: some View {
        EmptyView()
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                if !becomeActive {
                    terminationManager.addCleanupAction {
                        try? await server.shutdown()
                    }
                    
                    Task {
                        try await server.run()
                    }
                    
                    becomeActive = true
                }
            }
    }
}

#Preview {
    let timeRepository = FakeTimeRecordRepository()
    let userRepository = FakeUserRepository()
    let server = TimeCardServer(timeRepository, userRepository)
    ServerView(server: server)
}

private class FakeTimeRecordRepository: TimeRecordRepository {
    func getRecords(year: Int, month: Int) throws -> [TimeRecord] { [] }
    func getRecord(id: UUID) throws -> TimeRecord? { nil }
    func getBreakTime(id: UUID) throws -> TimeRecord.BreakTime? { nil }
    func insert(_ record: TimeRecord) throws {}
    func update(_ record: TimeRecord) throws {}
    func delete(_ record: TimeRecord) throws {}
    func getState() -> WorkState { .offWork }
    func checkIn() throws {}
    func checkOut() throws {}
    func startBreak() throws {}
    func endBreak() throws {}
}

private class FakeUserRepository: UserRepository {
    func register(mail: String, password: String) async throws {}
    func verify(mail: String, verifyCode: String) throws -> TokenPair { TokenPair(accessToken: "", refreshToken: "") }
    func login(mail: String, password: String) async throws -> TokenPair { TokenPair(accessToken: "", refreshToken: "") }
    func verifyLogin(token: String) -> Bool { true }
    func refresh(token: String) throws -> TokenPair { TokenPair(accessToken: "", refreshToken: "") }
    func purgeExpiredTokens() throws {}
}
