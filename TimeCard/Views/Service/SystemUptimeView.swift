//
//  SystemUptimeView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/15.
//

import SwiftUI

struct SystemUptimeView: View {
    @EnvironmentObject private var terminationManager: AppTerminationManager
    let uptimeRecord: SystemUptimeRecordViewModel
    @State private var becomeActive = false
    
    private let timer = Timer.publish(every: 60 * 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        EmptyView()
            .onReceive(timer) { _ in
                uptimeRecord.update()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                if !becomeActive {
                    terminationManager.addCleanupAction {
                        uptimeRecord.shutdown()
                    }
                    
                    uptimeRecord.launch()
                    becomeActive = true
                }
            }
            .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.willSleepNotification)) { _ in
                uptimeRecord.sleep()
                uptimeRecord.update()
            }
            .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)) { _ in
                uptimeRecord.wake()
                uptimeRecord.update()
            }
    }
}

#Preview {
    let terminationManager = AppTerminationManager()
    let repository = FakeUptimeRepository()
    let uptimeRecord = SystemUptimeRecordViewModel(repository: repository)
    SystemUptimeView(uptimeRecord: uptimeRecord)
        .environmentObject(terminationManager)
}

private class FakeUptimeRepository: SystemUptimeRecordRepository {
    func launch() throws {}
    func shutdown() throws {}
    func sleep() throws {}
    func wake() throws {}
    func update() throws {}
}
