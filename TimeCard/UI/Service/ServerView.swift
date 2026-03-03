//
//  ServerView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/28.
//

import SwiftUI

struct ServerView: View {
    @Environment(AppTerminationManager.self) private var terminationManager
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
    let terminationManager = AppTerminationManager()
    let repository = FakeTimeRecordRepository()
    let server = TimeCardServer(repository)
    ServerView(server: server)
        .environment(terminationManager)
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
