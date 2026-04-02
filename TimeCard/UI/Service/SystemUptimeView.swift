//
//  SystemUptimeView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/15.
//

import SwiftUI

struct SystemUptimeView: View {
    @Environment(\.terminationManager) private var terminationManager
    let viewModel: SystemUptimeRecordViewModel
    @State private var becomeActive = false
    
    private let timer = Timer.publish(every: 60 * 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        EmptyView()
            .onReceive(timer) { _ in
                viewModel.update()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                if !becomeActive {
                    terminationManager.addCleanupAction {
                        viewModel.shutdown()
                    }
                    
                    viewModel.launch()
                    becomeActive = true
                }
            }
            .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.willSleepNotification)) { _ in
                viewModel.sleep()
                viewModel.update()
            }
            .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)) { _ in
                viewModel.wake()
                viewModel.update()
            }
    }
}

#Preview {
    let repository = FakeUptimeRepository()
    let viewModel = SystemUptimeRecordViewModel(repository)
    SystemUptimeView(viewModel: viewModel)
}

private class FakeUptimeRepository: SystemUptimeRecordRepository {
    func launch() throws {}
    func shutdown() throws {}
    func sleep() throws {}
    func wake() throws {}
    func update() throws {}
    func restoreBackup() throws {}
}
