//
//  CalendarView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/02.
//

import SwiftUI

struct CalendarView: View {
    @State private var now: Date = Date.now
    
    var body: some View {
        VStack {
            HStack {
                Button("prev", systemImage: "chevron.left") {
                    refresh(addMonths: -1)
                }
                .labelStyle(.iconOnly)
                
                Text("\(String(now.year))-\(now.month)")
                    .font(.title)
                    .bold()
                
                Button("next", systemImage: "chevron.right") {
                    refresh(addMonths: 1)
                }
                .labelStyle(.iconOnly)
            }
            
            CalendarBodyView(year: now.year, month: now.month)
        }
        .padding()
        .onAppear {
            refresh(addMonths: 0)
        }
    }
    
    private func refresh(addMonths: Int) {
        if let date = Calendar.current.date(from: DateComponents(year: now.year, month: now.month + addMonths)) {
            now = date
        }
    }
}

#Preview {
    CalendarView()
}
