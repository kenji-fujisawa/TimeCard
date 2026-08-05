//
//  LaunchSettingView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/21.
//

import ServiceManagement
import SwiftUI

struct LaunchSettingView: View {
    @State private var launchAtLogin: Bool = false
    
    var body: some View {
        Form {
            Toggle(isOn: Binding<Bool>(
                get: { launchAtLogin },
                set: { toggleLaunchAtLogin(value: $0) }
            )) {
                Text("ログイン時にアプリを開く")
            }
            .toggleStyle(.switch)
        }
        .padding()
        .onAppear() {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
    
    private func toggleLaunchAtLogin(value: Bool) {
        if value {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}

#Preview {
    LaunchSettingView()
}
