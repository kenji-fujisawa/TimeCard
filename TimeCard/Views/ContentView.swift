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
                    NSApp.activate(ignoringOtherApps: true)
                    dismissWindow()
                } label: {
                    VStack {
                        Image(systemName: "calendar")
                            .padding(2)
                        Text("勤怠")
                            .font(.caption)
                    }
                    .frame(width: 30, height: 40)
                }
                
                SettingsLink {
                    VStack {
                        Image(systemName: "gearshape")
                            .padding(1)
                        Text("設定")
                            .font(.caption)
                    }
                    .frame(width: 30, height: 40)
                }
                .buttonStyle(.preAction {
                    NSApp.activate(ignoringOtherApps: true)
                    dismissWindow()
                })
                
                Button {
                    NotificationCenter.default.post(name: Notification.exitApp, object: nil)
                } label: {
                    VStack {
                        Image(systemName: "xmark.circle")
                            .padding(2)
                        Text("終了")
                            .font(.caption)
                    }
                    .frame(width: 30, height: 40)
                }
            }
        }
        .padding()
    }
}

private struct PreActionButtonStyle: PrimitiveButtonStyle {
    var preAction: () -> Void
    
    init(preAction: @escaping () -> Void) {
        self.preAction = preAction
    }
    
    func makeBody(configuration: Configuration) -> some View {
        Button(role: configuration.role) {
            preAction()
            configuration.trigger()
        } label: {
            configuration.label
        }
    }
}

extension PrimitiveButtonStyle where Self == PreActionButtonStyle {
    static func preAction(perform action: @escaping () -> Void) -> PreActionButtonStyle {
        PreActionButtonStyle(preAction: action)
    }
}

#Preview {
    ContentView()
}
