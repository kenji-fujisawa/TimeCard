//
//  MonthSelectorView.swift
//  TimeCard
//
//  Created by uhimania on 2025/12/29.
//

import SwiftUI

struct MonthSelectorView: View {
    @Binding var now: Date
    
    var body: some View {
        HStack {
            Button("prev", systemImage: "chevron.left") {
                refresh(addMonths: -1)
            }
            .labelStyle(.iconOnly)
            .accessibilityIdentifier("button_prev")
            
            Text(now, format: .dateTime.year().month())
                .font(.title)
                .bold()
                .environment(\.locale, Locale(identifier: "ja_JP"))
                .accessibilityIdentifier("text_month")
            
            Button("next", systemImage: "chevron.right") {
                refresh(addMonths: 1)
            }
            .labelStyle(.iconOnly)
            .accessibilityIdentifier("button_next")
        }
    }
    
    private func refresh(addMonths: Int) {
        if let date = Calendar.current.date(from: DateComponents(year: now.year, month: now.month + addMonths)) {
            now = date
        }
    }
}

#Preview {
    @Previewable @State var date = Date.now
    MonthSelectorView(now: $date)
}
