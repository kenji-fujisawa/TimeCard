//
//  ContentView.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/29.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var toast = ToastViewModel()
    @ObservedObject private var calendar: CalendarViewModel
    
    init() {
        let source = DefaultNetworkDataSource()
        let repository = DefaultCalendarRecordRepository(networkDataSource: source)
        self.calendar = CalendarViewModel(repository: repository)
    }
    
    var body: some View {
        VStack {
            CalendarView(model: calendar)
        }
        .padding()
        .overlay {
            ToastView(model: toast)
        }
        .environmentObject(toast)
    }
}

#Preview {
    ContentView()
}
