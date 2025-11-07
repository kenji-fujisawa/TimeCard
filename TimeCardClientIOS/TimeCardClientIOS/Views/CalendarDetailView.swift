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
        @EnvironmentObject private var toast: ToastViewModel
        @Binding var record: TimeRecord
        @State private var original: TimeRecord? = nil
        
        var body: some View {
            Section {
                DatePicker("出勤", selection: $record.checkIn.bindUnwrap(defaultValue: .now), displayedComponents: [.hourAndMinute])
                DatePicker("退勤", selection: $record.checkOut.bindUnwrap(defaultValue: .now), displayedComponents: [.hourAndMinute])
                
                ForEach($record.breakTimes) { $breakTime in
                    BreakTimeView(breakTime: $breakTime)
                }
            }
            .onAppear() {
                original = record
            }
            .onDisappear() {
                if record != original {
                    update()
                }
            }
        }
        
        private func update() {
            TaskQueue.shared.add {
                do {
                    var url = URL(string: "http://192.168.4.33:8080/timecard/records")
                    url = url?.appending(path: record.id.uuidString)
                    guard let url = url else { return }
                    
                    let json = try JSONEncoder().encode(record)
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "PATCH"
                    request.httpBody = json
                    
                    let (data, response) = try await URLSession.shared.data(for: request)
                    if let response = response as? HTTPURLResponse,
                       response.statusCode != 200 {
                        onUpdateFailed()
                        return
                    }
                    
                    if let records = try? JSONDecoder().decode([TimeRecord].self, from: data),
                       let record = records.first {
                        self.record = record
                    }
                } catch {
                    onUpdateFailed()
                }
            }
        }
        
        private func onUpdateFailed() {
            withAnimation {
                toast.isPresented = true
                toast.message = "出勤・退勤を更新できませんでした"
                
                if let record = original {
                    self.record = record
                }
            }
        }
    }
    
    private struct BreakTimeView: View {
        @Binding var breakTime: TimeRecord.BreakTime
        
        var body: some View {
            Group {
                DatePicker("休憩開始", selection: $breakTime.start.bindUnwrap(defaultValue: .now), displayedComponents: [.hourAndMinute])
                DatePicker("休憩終了", selection: $breakTime.end.bindUnwrap(defaultValue: .now), displayedComponents: [.hourAndMinute])
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
        .environmentObject(ToastViewModel())
}
