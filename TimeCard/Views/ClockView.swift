//
//  ClockView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/01.
//

import SwiftUI

struct ClockView: View {
    @State private var now = Date.now
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Text(now, format: .dateTime.year().month().day())
                .environment(\.locale, Locale(identifier: "ja_JP"))
            
            Text(now, format: .dateTime.hour().minute().second())
                .font(.system(.largeTitle, design: .monospaced))
                .bold()
                .padding(5)
                .onReceive(timer) { input in
                    now = input
                }
        }
    }
}

#Preview {
    ClockView()
}
