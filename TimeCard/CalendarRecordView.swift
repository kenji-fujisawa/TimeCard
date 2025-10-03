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
        HStack {
            Text("\(String(format: "%02d", record.date.day))(\(record.date.weekDay))")
                .foregroundStyle(record.date.isHoliday() ? .red : .black)
            
            VStack {
                ForEach(record.records) { record in
                    if let checkIn = record.checkIn {
                        Text("\(String(format: "%02d", checkIn.hour)):\(String(format: "%02d", checkIn.minute))")
                    } else {
                        Text(" ")
                    }
                }
            }
            
            VStack {
                ForEach(record.records) { record in
                    if let checkOut = record.checkOut {
                        Text("\(String(format: "%02d", checkOut.hour)):\(String(format: "%02d", checkOut.minute))")
                    } else {
                        Text(" ")
                    }
                }
            }
        }
        .font(.system(.headline, design: .monospaced))
        .fontWeight(.regular)
    }
}

#Preview {
    let rec1 = TimeRecord(year: Date.now.year, month: Date.now.month, checkIn: .now, checkOut: .now)
    let rec2 = TimeRecord(year: Date.now.year, month: Date.now.month, checkIn: .now)
    let record = CalendarRecord(date: .now, records: [rec1, rec2])
    CalendarRecordView(record: record)
}
