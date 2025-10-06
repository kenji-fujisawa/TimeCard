//
//  CalendarRecordView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/03.
//

import SwiftUI

struct CalendarRecordView: View {
    let record: CalendarRecord
    
    var body: some View {
        GridRow {
            Text(record.date, format: .dayWithWeekday)
                .foregroundStyle(record.date.isHoliday() ? .red : .black)
            
            VStack {
                ForEach(record.records) { record in
                    if let checkIn = record.checkIn {
                        Text(checkIn, format: .dateTime.hour().minute())
                    } else {
                        Text(" ")
                    }
                }
            }
            
            VStack {
                ForEach(record.records) { record in
                    if let checkOut = record.checkOut {
                        Text(checkOut, format: .dateTime.hour().minute())
                    } else {
                        Text(" ")
                    }
                }
            }
        }
        .font(.system(.headline, design: .monospaced))
        .fontWeight(.regular)
        
        Divider()
    }
}

#Preview {
    let rec1 = TimeRecord(year: Date.now.year, month: Date.now.month, checkIn: .now, checkOut: .now)
    let rec2 = TimeRecord(year: Date.now.year, month: Date.now.month, checkIn: .now)
    let record = CalendarRecord(date: .now, records: [rec1, rec2])
    Grid {
        CalendarRecordView(record: record)
    }
}
