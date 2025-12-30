//
//  RecorderView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/21.
//

import SwiftData
import SwiftUI

struct RecorderView: View {
    @Environment(\.modelContext) private var context
    @Query private var records: [TimeRecord]
    
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
                    VStack {
                        Image(systemName: "play.desktopcomputer")
                            .font(.title)
                            .foregroundStyle(.cyan)
                            .padding(2)
                        Text("出勤")
                            .font(.caption)
                    }
                    .frame(width: 50, height: 50)
                }
                .accessibilityIdentifier("button_check_in")
            } else if records.last?.state == .AtBreak {
                Button {
                    endBreak()
                } label: {
                    VStack {
                        Image(systemName: "power.circle")
                            .font(.title)
                            .foregroundStyle(.orange)
                            .padding(2)
                        Text("休憩終了")
                            .font(.caption)
                    }
                    .frame(width: 50, height: 50)
                }
                .accessibilityIdentifier("button_break_end")
            } else if records.last?.state == .AtWork {
                HStack {
                    Button {
                        checkOut()
                    } label: {
                        VStack {
                            Image(systemName: "powersleep")
                                .font(.title)
                                .foregroundStyle(.yellow)
                                .padding(2)
                            Text("退勤")
                                .font(.caption)
                        }
                        .frame(width: 50, height: 50)
                    }
                    .accessibilityIdentifier("button_check_out")
                    
                    Button {
                        startBreak()
                    } label: {
                        VStack {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.title)
                                .foregroundStyle(.purple)
                                .padding(2)
                            Text("休憩")
                                .font(.caption)
                        }
                        .frame(width: 50, height: 50)
                    }
                    .accessibilityIdentifier("button_break_start")
                }
            }
        }
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
    RecorderView()
        .modelContainer(for: TimeRecord.self, inMemory: true)
}
