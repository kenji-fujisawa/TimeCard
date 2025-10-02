//
//  CalendarView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/02.
//

import SwiftUI

struct CalendarView: View {
    @State var now: Date = Date.now
    @State var dates: [Date] = []
    
    var body: some View {
        VStack {
            HStack {
                Button("prev", systemImage: "chevron.left") {
                    updateDates(addMonths: -1)
                }
                .labelStyle(.iconOnly)
                
                Text("\(String(now.year))-\(now.month)")
                    .font(.title)
                    .bold()
                
                Button("next", systemImage: "chevron.right") {
                    updateDates(addMonths: 1)
                }
                .labelStyle(.iconOnly)
            }
            
            List {
                ForEach(dates, id: \.self) { date in
                    Text("\(date.day)(\(date.weekDay))")
                        .font(.system(.headline, design: .monospaced))
                        .fontWeight(.regular)
                        .foregroundStyle(date.isHoliday() ? .red : .black)
                }
            }
        }
        .padding()
        .onAppear {
            updateDates(addMonths: 0)
        }
    }
    
    private func updateDates(addMonths: Int) {
        if let date = Calendar.current.date(from: DateComponents(year: now.year, month: now.month + addMonths)) {
            now = date
        }
        
        dates = Calendar.current.datesOf(year: now.year, month: now.month)
    }
}

#Preview {
    CalendarView()
}
