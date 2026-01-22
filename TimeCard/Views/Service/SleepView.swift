//
//  SleepView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/25.
//

import SwiftData
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
    func getState() -> WorkState { .OffWork }
    func checkIn() throws {}
    func checkOut() throws {}
    func startBreak() throws {}
    func endBreak() throws {}
}
