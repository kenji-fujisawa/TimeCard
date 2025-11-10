//
//  ContentView.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/10/29.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var toast = ToastViewModel()
    @ObservedObject private var calendarModel = CalendarViewModel()
    
    var body: some View {
        VStack {
            CalendarView(model: calendarModel)
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
