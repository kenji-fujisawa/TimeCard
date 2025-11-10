//
//  SystemUptimeView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/15.
//

import SwiftUI

struct SystemUptimeView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var terminationManager: AppTerminationManager
    @State private var record: SystemUptimeRecord
    @State private var becomeActive = false
    
    private let timer = Timer.publish(every: 60 * 5, on: .main, in: .common).autoconnect()
    
    init() {
        let now = Date.now
        let uptime = ProcessInfo.processInfo.systemUptime
        self.record = SystemUptimeRecord(year: now.year, month: now.month, day: now.day, launch: uptime, shutdown: uptime)
    }
    
    var body: some View {
        EmptyView()
            .onReceive(timer) { _ in
                recordShutdown()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                if !becomeActive {
                    terminationManager.addCleanupAction {
                        recordShutdown()
                        try? context.save()
                    }
                    
                    context.insert(self.record)
                    becomeActive = true
                }
            }
    }
    
    private func recordShutdown() {
        let uptime = ProcessInfo.processInfo.systemUptime
        record.shutdown = uptime
        
        let now = Date.now
        if record.day != now.day {
            record = SystemUptimeRecord(year: now.year, month: now.month, day: now.day, launch: uptime, shutdown: uptime)
            context.insert(record)
        }
    }
}

#Preview {
    SystemUptimeView()
}
