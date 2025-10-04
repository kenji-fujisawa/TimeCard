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
            
            Button {
                addRecord()
            } label: {
                Text(isWorking() ? "退勤" : "出勤")
                    .bold()
                    .padding()
            }
            
            CalendarView()
        }
        .padding()
    }
    
    private func isWorking() -> Bool {
        !records.isEmpty && records.last?.checkOut == nil
    }
    
    private func addRecord() {
        if isWorking() {
            records.last?.checkOut = Date.now
        } else {
            let now = Date.now
            context.insert(TimeRecord(year: now.year, month: now.month, checkIn: now))
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TimeRecord.self, inMemory: true)
}
