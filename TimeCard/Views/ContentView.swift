//
//  ContentView.swift
//  TimeCard
//
//  Created by uhimania on 2025/09/24.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query var records: [TimeRecord]
    
    init() {
        let now = Date.now
        let year = now.year
        let month = now.month
        _records = Query(filter: #Predicate<TimeRecord> { $0.year == year && $0.month == month }, sort: \.checkIn)
    }
    
    var body: some View {
        VStack {
            ClockView()
            
            if records.isEmpty || records.last?.state == .OffWork {
                Button {
                    checkIn()
                } label: {
                    Text("出勤")
                        .bold()
                        .padding()
                }
            } else if records.last?.state == .AtBreak {
                Button {
                    endBreak()
                } label: {
                    Text("休憩終了")
                        .bold()
                        .padding()
                }
            } else if records.last?.state == .AtWork {
                HStack {
                    Button {
                        checkOut()
                    } label: {
                        Text("退勤")
                            .bold()
                            .padding()
                    }
                    Button {
                        startBreak()
                    } label: {
                        Text("休憩")
                            .bold()
                            .padding()
                    }
                }
            }
            
            CalendarView()
        }
        .padding()
    }
    
    private func checkIn() {
        let now = Date.now
        context.insert(TimeRecord(year: now.year, month: now.month, checkIn: now))
    }
    
    private func checkOut() {
        records.last?.checkOut = Date.now
    }
    
    private func startBreak() {
        let breakTime = TimeRecord.BreakTime(start: .now)
        records.last?.breakTimes.append(breakTime)
    }
    
    private func endBreak() {
        records.last?.sortedBreakTimes.last?.end = .now
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TimeRecord.self, inMemory: true)
}
