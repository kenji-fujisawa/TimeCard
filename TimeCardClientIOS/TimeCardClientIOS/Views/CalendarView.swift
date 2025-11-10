//
//  CalendarView.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/29.
//

import SwiftUI

class CalendarViewModel: ObservableObject {
    @Published var now: Date = .now
    @Published var records: [CalendarRecord]? = nil
    @Published var error: Bool = false
    
    init() {
        fetchRecords()
    }
    
    func fetchRecords() {
        records = nil
        error = false
        
        var url = URL(string: "http://192.168.4.33:8080/timecard/records")
        url = url?.appending(queryItems: [.init(name: "year", value: String(now.year))])
        url = url?.appending(queryItems: [.init(name: "month", value: String(now.month))])
        guard let url = url else { return toCalendarRecords(records: []) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            var records: [TimeRecord] = []
            defer {
                Task { @MainActor in
                    self.toCalendarRecords(records: records)
                }
            }
            
            if error != nil {
                Task { @MainActor in
                    self.error = true
                }
            }
            
            if let response = response as? HTTPURLResponse,
               response.statusCode != 200 {
                Task { @MainActor in
                    self.error = true
                }
            }
            
            guard let data = data else { return }
            let decoder = JSONDecoder()
            if let recs = try? decoder.decode([TimeRecord].self, from: data) {
                records = recs
            }
        }
        task.resume()
    }
    
    private func toCalendarRecords(records: [TimeRecord]) {
        let dates = Calendar.current.datesOf(year: now.year, month: now.month)
        
        var timeRecords: [Int: [TimeRecord]] = [:]
        for rec in records {
            if let day = rec.checkIn?.day {
                if timeRecords[day] == nil {
                    timeRecords[day] = []
                }
                timeRecords[day]?.append(rec)
            }
        }
        
        var results: [CalendarRecord] = []
        for date in dates {
            results.append(CalendarRecord(date: date, records: timeRecords[date.day] ?? []))
        }
        
        self.records = results
    }
}

struct CalendarView: View {
    @EnvironmentObject private var toast: ToastViewModel
    @ObservedObject var model: CalendarViewModel
    
    var body: some View {
        NavigationStack {
            if model.records != nil {
                HStack {
                    Button("prev", systemImage: "chevron.left") {
                        refresh(addMonths: -1)
                    }
                    .labelStyle(.iconOnly)
                    
                    Text(model.now, format: .dateTime.year().month())
                        .font(.title)
                        .bold()
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                    
                    Button("next", systemImage: "chevron.right") {
                        refresh(addMonths: 1)
                    }
                    .labelStyle(.iconOnly)
                }
                
                ScrollView {
                    Grid {
                        GridRow {
                            Text("")
                            Text("出勤")
                            Text("退勤")
                            Text("休始")
                            Text("休終")
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                        
                        ForEach($model.records.bindUnwrap(defaultValue: [])) { $record in
                            NavigationLink {
                                CalendarDetailView(record: $record)
                            } label: {
                                CalendarRecordView(record: record)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                        }
                    }
                }
                .padding()
            } else {
                ProgressView()
            }
        }
        .onChange(of: model.error) { _, newValue in
            if newValue == true {
                withAnimation {
                    toast.isPresented = true
                    toast.message = "データを取得できませんでした"
                }
            }
        }
    }
    
    private func refresh(addMonths: Int) {
        if let date = Calendar.current.date(from: DateComponents(year: model.now.year, month: model.now.month + addMonths)) {
            withAnimation {
                model.now = date
                model.fetchRecords()
            }
        }
    }
}

#Preview {
    let model = CalendarViewModel()
    CalendarView(model: model)
        .environmentObject(ToastViewModel())
}
