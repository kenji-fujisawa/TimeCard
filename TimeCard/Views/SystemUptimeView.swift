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
    @State private var inSleep = false
    
    private let timer = Timer.publish(every: 60 * 5, on: .main, in: .common).autoconnect()
    
    init() {
        let now = Date.now
        self.record = SystemUptimeRecord(year: now.year, month: now.month, day: now.day, launch: now, shutdown: now)
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
            .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.willSleepNotification)) { _ in
                let now = Date.now
                let sleep = SystemUptimeRecord.SleepRecord(start: now, end: now)
                record.sleepRecords.append(sleep)
                inSleep = true
            }
            .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)) { _ in
                if let sleep = record.sortedSleepRecords.last {
                    sleep.end = Date.now
                }
                inSleep = false
            }
    }
    
    private func recordShutdown() {
        let now = Date.now
        record.shutdown = now
        
        if inSleep,
           let sleep = record.sortedSleepRecords.last {
            sleep.end = now
        }
        
        if record.day != now.day {
            record = SystemUptimeRecord(year: now.year, month: now.month, day: now.day, launch: now, shutdown: now)
            context.insert(record)
            
            if inSleep {
                let sleep = SystemUptimeRecord.SleepRecord(start: now, end: now)
                record.sleepRecords.append(sleep)
            }
        }
    }
}

#Preview {
    let terminationManager = AppTerminationManager()
    SystemUptimeView()
        .environmentObject(terminationManager)
}
