//
//  SleepView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/25.
//

import SwiftData
import SwiftUI

struct SleepView: View {
    @Query private var records: [TimeRecord]
    @State private var breakTime: TimeRecord.BreakTime? = nil
    
    init() {
        let now = Date.now
        let year = now.year
        let month = now.month
        _records = Query(filter: #Predicate<TimeRecord> { $0.year == year && $0.month == month }, sort: \.checkIn)
    }
    
    var body: some View {
        EmptyView()
            .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.willSleepNotification)) { _ in
                startBreak()
            }
            .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)) { _ in
                endBreak()
            }
    }
    
    private func startBreak() {
        if let record = records.last {
            if record.state == .AtWork {
                let breakTime = TimeRecord.BreakTime(start: Date.now)
                record.breakTimes.append(breakTime)
                self.breakTime = breakTime
            }
        }
    }
    
    private func endBreak() {
        if let breakTime = self.breakTime {
            breakTime.end = Date.now
            self.breakTime = nil
        }
    }
}

#Preview {
    SleepView()
}
