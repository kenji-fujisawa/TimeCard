//
//  SleepView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/25.
//

import SwiftUI

struct SleepView: View {
    let timeRecord: TimeRecordViewModel
    
    var body: some View {
        EmptyView()
            .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.willSleepNotification)) { _ in
                timeRecord.startBreak()
            }
            .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)) { _ in
                timeRecord.endBreak()
            }
    }
}

#Preview {
    let repository = FakeTimeRecordRepository()
    let timeRecord = TimeRecordViewModel(repository: repository)
    SleepView(timeRecord: timeRecord)
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
