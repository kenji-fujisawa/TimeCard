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
    @Query(sort: \TimeRecord.checkIn) var records: [TimeRecord]
    
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
            
            List {
                ForEach(records) { record in
                    HStack {
                        Text(record.checkIn?.formatted() ?? "")
                        Text(record.checkOut?.formatted() ?? "")
                    }
                }
            }
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
            context.insert(TimeRecord(checkIn: Date.now))
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TimeRecord.self, inMemory: true)
}
