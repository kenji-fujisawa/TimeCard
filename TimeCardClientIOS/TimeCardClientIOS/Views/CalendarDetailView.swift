//
//  CalendarDetailView.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/31.
//

import SwiftUI

struct CalendarDetailView: View {
    @Binding var record: CalendarRecord
    
    var body: some View {
        VStack {
            Text(record.date, format: .dateTime.month().day().weekday())
                .foregroundStyle(record.date.isHoliday() ? .red : .black)
                .environment(\.locale, Locale(identifier: "ja_JP"))
            
            Form {
                ForEach($record.records) { $record in
                    TimeRecordView(record: $record)
                }
            }
        }
        .padding()
    }
    
    private struct TimeRecordView: View {
        @Binding var record: TimeRecord
        @State private var changed = false
        
        var body: some View {
            Section {
                DatePicker("出勤", selection: $record.checkIn.bindUnwrap(defaultValue: .now), displayedComponents: [.hourAndMinute])
                    .onChange(of: record.checkIn) { _, _ in
                        changed = true
                    }
                DatePicker("退勤", selection: $record.checkOut.bindUnwrap(defaultValue: .now), displayedComponents: [.hourAndMinute])
                    .onChange(of: record.checkOut) { _, _ in
                        changed = true
                    }
                
                ForEach($record.breakTimes) { $breakTime in
                    BreakTimeView(breakTime: $breakTime)
                }
            }
            .onDisappear() {
                if changed {
                    update()
                }
            }
        }
        
        private func update() {
            TaskQueue.shared.add {
                var url = URL(string: "http://192.168.4.33:8080/timecard/records")
                url = url?.appending(path: record.id.uuidString)
                guard let url = url else { return }
                
                let json = try? JSONEncoder().encode(record)
                
                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.httpBody = json
                
                let _ = try? await URLSession.shared.data(for: request)
            }
        }
    }
    
    private struct BreakTimeView: View {
        @Binding var breakTime: TimeRecord.BreakTime
        @State private var changed = false
        
        var body: some View {
            Group {
                DatePicker("休憩開始", selection: $breakTime.start.bindUnwrap(defaultValue: .now), displayedComponents: [.hourAndMinute])
                    .onChange(of: breakTime.start) { _, _ in
                        changed = true
                    }
                DatePicker("休憩終了", selection: $breakTime.end.bindUnwrap(defaultValue: .now), displayedComponents: [.hourAndMinute])
                    .onChange(of: breakTime.end) { _, _ in
                        changed = true
                    }
            }
            .onDisappear() {
                if changed {
                    update()
                }
            }
        }
        
        private func update() {
            TaskQueue.shared.add {
                var url = URL(string: "http://192.168.4.33:8080/timecard/breaktime")
                url = url?.appending(path: breakTime.id.uuidString)
                guard let url = url else { return }
                
                let json = try? JSONEncoder().encode(breakTime)
                
                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.httpBody = json
                
                let _ = try? await URLSession.shared.data(for: request)
            }
        }
    }
}

#Preview {
    @Previewable @State var record = CalendarRecord(date: .now, records: [
        TimeRecord(id: UUID(), year: Date.now.year, month: Date.now.month, checkIn: .now, checkOut: .now, breakTimes: [
            TimeRecord.BreakTime(id: UUID(), start: .now, end: .now),
            TimeRecord.BreakTime(id: UUID(), start: .now, end: .now)
        ]),
        TimeRecord(id: UUID(), year: Date.now.year, month: Date.now.month, checkIn: .now, checkOut: .now, breakTimes: [
            TimeRecord.BreakTime(id: UUID(), start: .now, end: .now),
        ])
    ])
    CalendarDetailView(record: $record)
}
