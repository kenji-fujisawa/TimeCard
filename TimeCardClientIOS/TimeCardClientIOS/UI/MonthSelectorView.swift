//
//  MonthSelectorView.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/12/30.
//

import SwiftUI

struct MonthSelectorView: View {
    @Binding var date: Date
    
    var body: some View {
        HStack {
            Button("prev", systemImage: "chevron.left") {
                refresh(addMonths: -1)
            }
            .labelStyle(.iconOnly)
            .accessibilityIdentifier("button_prev")
            
            Text(date, format: .dateTime.year().month())
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
        if let date = Calendar.current.date(from: DateComponents(year: date.year, month: date.month + addMonths)) {
            withAnimation {
                self.date = date
            }
        }
    }
}

#Preview {
    @Previewable @State var date = Date.now
    MonthSelectorView(date: $date)
}
