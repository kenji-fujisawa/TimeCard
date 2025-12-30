//
//  TimeCardClientIOSApp.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/29.
//

import SwiftUI

struct TimeCardClientIOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct UITestApp: App {
    private let formatter: DateFormatter
    @State private var now: Date
    @State private var record: CalendarRecord
    @StateObject private var toast = ToastViewModel()
    
    init() {
        formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        now = formatter.date(from: "2025-12-29 00:00:00") ?? .now
        
        record = CalendarRecord(
            date: formatter.date(from: "2025-12-29 00:00:00") ?? .now,
            records: [
                TimeRecord(
                    id: UUID(),
                    year: 2025,
                    month: 12,
                    checkIn: formatter.date(from: "2025-12-29 09:12:38"),
                    checkOut: formatter.date(from: "2025-12-30 02:28:11"),
                    breakTimes: [
                        TimeRecord.BreakTime(
                            id: UUID(),
                            start: formatter.date(from: "2025-12-29 23:45:58"),
                            end: formatter.date(from: "2025-12-30 01:30:45")
                        )
                    ]
                )
            ]
        )
    }
    
    var body: some Scene {
        WindowGroup {
            if CommandLine.arguments.contains("MonthSelectorViewTests") {
                MonthSelectorView(now: $now)
            } else if CommandLine.arguments.contains("CalendarRecordViewTests") {
                CalendarRecordView(record: record)
            } else if CommandLine.arguments.contains("CalendarDetailViewTests") {
                NavigationStack {
                    CalendarDetailView(record: $record)
                }
            } else if CommandLine.arguments.contains("ToastViewTests") {
                ToastView(model: toast)
                Button("show") {
                    toast.message = "test message"
                    toast.isPresented = true
                }
                .accessibilityIdentifier("button_show_toast")
            }
        }
    }
}
