//
//  ContentView.swift
//  TimeCard
//
//  Created by uhimania on 2025/09/24.
//

import SwiftUI

extension Notification {
    static let exitApp = Notification.Name("exitApp")
}

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        VStack {
            RecorderView()
            
            Divider()
            
            HStack {
                Button {
                    openWindow(id: "calendar")
                    dismissWindow()
                } label: {
                    VStack {
                        Image(systemName: "calendar")
                            .padding(2)
                        Text("勤怠")
                    }
                    .padding(3)
                }
                
                Button {
                    NotificationCenter.default.post(name: Notification.exitApp, object: nil)
                } label: {
                    VStack {
                        Image(systemName: "xmark.circle")
                            .padding(2)
                        Text("終了")
                    }
                    .padding(3)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
