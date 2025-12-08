//
//  RecordEditView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/07.
//

import SwiftUI

struct RecordEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State var record: CalendarRecord
    
    var body: some View {
        TabView {
            Tab("労働時間", systemImage: "person.circle.fill") {
                TimeRecordEditView(record: record)
            }
            Tab("システム稼働時間", systemImage: "power.circle.fill") {
                SystemUptimeRecordEditView(record: record)
            }
        }
        .padding()
        .toolbar {
            ToolbarItem {
                Button("閉じる", systemImage: "xmark") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    let break1 = TimeRecord.BreakTime(start: .now, end: .now)
    let break2 = TimeRecord.BreakTime(start: .now)
    let rec1 = TimeRecord(year: 2025, month: 10, checkIn: .now, checkOut: .now, breakTimes: [break1, break2])
    let rec2 = TimeRecord(year: 2025, month: 10, checkIn: .now, breakTimes: [break1])
    let uptime = SystemUptimeRecord(year: Date.now.year, month: Date.now.month, day: Date.now.day, launch: Date.now, shutdown: Date.now)
    let record = CalendarRecord(date: .now, records: [rec1, rec2], systemUptimeRecords: [uptime])
    RecordEditView(record: record)
}
