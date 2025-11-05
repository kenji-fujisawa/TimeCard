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
                if record.checkIn != original?.checkIn || record.checkOut != original?.checkOut {
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
                    request.httpMethod = "PUT"
                    request.httpBody = json
                    
                    let (data, response) = try await URLSession.shared.data(for: request)
                    if let response = response as? HTTPURLResponse,
                       response.statusCode != 200 {
                        onUpdateFailed()
                        return
                    }
                    
                    if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                       let rec = json.first,
                       let id = rec["id"] as? String,
                       let checkIn = rec["checkIn"] as? Double,
                       let checkOut = rec["checkOut"] as? Double,
                       record.id.uuidString == id {
                        record.checkIn = Date(timeIntervalSinceReferenceDate: checkIn)
                        record.checkOut = Date(timeIntervalSinceReferenceDate: checkOut)
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
                
                record.checkIn = original?.checkIn
                record.checkOut = original?.checkOut
            }
        }
    }
    
    private struct BreakTimeView: View {
        @EnvironmentObject private var toast: ToastViewModel
        @Binding var breakTime: TimeRecord.BreakTime
        @State private var original: TimeRecord.BreakTime? = nil
        
        var body: some View {
            Group {
                DatePicker("休憩開始", selection: $breakTime.start.bindUnwrap(defaultValue: .now), displayedComponents: [.hourAndMinute])
                DatePicker("休憩終了", selection: $breakTime.end.bindUnwrap(defaultValue: .now), displayedComponents: [.hourAndMinute])
            }
            .onAppear() {
                original = breakTime
            }
            .onDisappear() {
                if breakTime.start != original?.start || breakTime.end != original?.end {
                    update()
                }
            }
        }
        
        private func update() {
            TaskQueue.shared.add {
                do {
                    var url = URL(string: "http://192.168.4.33:8080/timecard/breaktime")
                    url = url?.appending(path: breakTime.id.uuidString)
                    guard let url = url else { return }
                    
                    let json = try JSONEncoder().encode(breakTime)
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "PUT"
                    request.httpBody = json
                    
                    let (data, response) = try await URLSession.shared.data(for: request)
                    if let response = response as? HTTPURLResponse,
                       response.statusCode != 200 {
                        onUpdateFailed()
                        return
                    }
                    
                    if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                       let rec = json.first,
                       let id = rec["id"] as? String,
                       let start = rec["start"] as? Double,
                       let end = rec["end"] as? Double,
                       breakTime.id.uuidString == id {
                        breakTime.start = Date(timeIntervalSinceReferenceDate: start)
                        breakTime.end = Date(timeIntervalSinceReferenceDate: end)
                    }
                } catch {
                    onUpdateFailed()
                }
            }
        }
        
        private func onUpdateFailed() {
            withAnimation {
                toast.isPresented = true
                toast.message = "休憩時間を更新できませんでした"
                
                breakTime.start = original?.start
                breakTime.end = original?.end
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
