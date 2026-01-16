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
            MonthSelectorView(now: $now)
            
            CalendarBodyView(year: now.year, month: now.month)
        }
        .padding()
        .toolbar {
            ExportPDFView()
        }
    }
}

#Preview {
    CalendarView()
}
