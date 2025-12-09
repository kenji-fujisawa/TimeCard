//
//  CalendarDetailView.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/31.
//

import SwiftUI

struct CalendarDetailView: View {
    @EnvironmentObject private var toast: ToastViewModel
    @Binding var record: CalendarRecord
    @State private var original: CalendarRecord? = nil
    @State private var results: [TimeRecord] = []
    
    var body: some View {
        VStack {
            Text(record.date, format: .dateTime.month().day().weekday())
                .foregroundStyle(record.date.isHoliday() ? .red : .black)
                .environment(\.locale, Locale(identifier: "ja_JP"))
            
            Form {
                ForEach($record.records) { $record in
                    TimeRecordView(record: $record)
                }
                .onDelete(perform: deleteItems)
                
                Button("勤怠を追加", systemImage: "plus") {
                    addItem()
                }
                .frame(maxWidth: .infinity)
            }
            .toolbar {
                ToolbarItem {
                    EditButton()
                }
            }
        }
        .padding()
        .onAppear() {
            original = record
        }
        .onDisappear() {
            if record.records != original?.records {
                saveChanges()
            }
        }
    }
    
    private func addItem() {
        let rec = TimeRecord(id: UUID(), year: record.date.year, month: record.date.month, checkIn: record.date, checkOut: record.date, breakTimes: [])
        record.records.append(rec)
    }
    
    private func deleteItems(indexes: IndexSet) {
        record.records.remove(atOffsets: indexes)
    }
    
    private func saveChanges() {
        guard let original = original else { return }
        
        results = record.records
        
        let diff = record.records.difference(from: original.records)
        for change in diff {
            switch change {
            case .insert(_, let record, _):
                if original.records.contains(where: { $0.id == record.id }) {
                    sendUpdate(record: record)
                    results.removeAll(where: { $0 == record })
                } else {
                    sendInsert(record: record)
                    results.removeAll(where: { $0 == record })
                }
            case .remove(_, let record, _):
                if !self.record.records.contains(where: { $0.id == record.id }) {
                    sendDelete(record: record)
                }
            }
        }
        
        TaskQueue.shared.add {
            results.sort(by: { $0.checkIn ?? .distantPast < $1.checkIn ?? .distantPast })
            record.records = results
        }
    }
    
    private func sendInsert(record: TimeRecord) {
        TaskQueue.shared.add {
            do {
                let url = URL(string: "http://192.168.4.33:8080/timecard/records")
                guard let url = url else { return }
                
                let json = try JSONEncoder().encode(record)
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.httpBody = json
                
                let (data, response) = try await URLSession.shared.data(for: request)
                if let response = response as? HTTPURLResponse,
                   response.statusCode != 200 {
                    showFailure()
                    return
                }
                
                if let records = try? JSONDecoder().decode([TimeRecord].self, from: data),
                   let record = records.first {
                    results.append(record)
                }
            } catch {
                showFailure()
            }
        }
    }
    
    private func sendUpdate(record: TimeRecord) {
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
                    if let org = original?.records.first(where: { $0.id == record.id }) {
                        results.append(org)
                    }
                    showFailure()
                    return
                }
                
                if let records = try? JSONDecoder().decode([TimeRecord].self, from: data),
                   let record = records.first {
                    results.append(record)
                }
            } catch {
                if let org = original?.records.first(where: { $0.id == record.id }) {
                    results.append(org)
                }
                showFailure()
            }
        }
    }
    
    private func sendDelete(record: TimeRecord) {
        TaskQueue.shared.add {
            do {
                var url = URL(string: "http://192.168.4.33:8080/timecard/records")
                url = url?.appendingPathComponent(record.id.uuidString)
                guard let url = url else { return }
                
                var request = URLRequest(url: url)
                request.httpMethod = "DELETE"
                
                let (_, response) = try await URLSession.shared.data(for: request)
                if let response = response as? HTTPURLResponse,
                   response.statusCode != 200 {
                    results.append(record)
                    showFailure()
                }
            } catch {
                results.append(record)
                showFailure()
            }
        }
    }
    
    private func showFailure() {
        Task { @MainActor in
            toast.isPresented = true
            toast.message = "更新に失敗しました"
        }
    }
    
    private struct TimeRecordView: View {
        @EnvironmentObject private var toast: ToastViewModel
        @Binding var record: TimeRecord
        @State private var original: TimeRecord? = nil
        
        var body: some View {
            Section {
                VStack {
                    DatePicker("出勤", selection: $record.checkIn.bindUnwrap(defaultValue: .now), displayedComponents: [.date, .hourAndMinute])
                    Divider()
                    DatePicker("退勤", selection: $record.checkOut.bindUnwrap(defaultValue: .now), displayedComponents: [.date, .hourAndMinute])
                }
                
                ForEach($record.breakTimes) { $breakTime in
                    BreakTimeView(breakTime: $breakTime)
                }
                .onDelete(perform: deleteItems)
                
                Button("休憩を追加", systemImage: "plus") {
                    record.breakTimes.append(TimeRecord.BreakTime(id: UUID(), start: record.checkIn, end: record.checkIn))
                }
                .frame(maxWidth: .infinity)
                .deleteDisabled(true)
            }
        }
        
        private func deleteItems(indexes: IndexSet) {
            record.breakTimes.remove(atOffsets: indexes)
        }
    }
    
    private struct BreakTimeView: View {
        @Binding var breakTime: TimeRecord.BreakTime
        
        var body: some View {
            VStack {
                DatePicker("休憩開始", selection: $breakTime.start.bindUnwrap(defaultValue: .now), displayedComponents: [.date, .hourAndMinute])
                Divider()
                DatePicker("休憩終了", selection: $breakTime.end.bindUnwrap(defaultValue: .now), displayedComponents: [.date, .hourAndMinute])
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
    NavigationStack {
        CalendarDetailView(record: $record)
            .environmentObject(ToastViewModel())
    }
}
