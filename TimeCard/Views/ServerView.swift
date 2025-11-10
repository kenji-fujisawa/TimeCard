//
//  ServerView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/28.
//

import SwiftUI

struct ServerView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var terminationManager: AppTerminationManager
    @State private var server: TimeCardServer!
    @State private var becomeActive = false
    
    var body: some View {
        EmptyView()
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                if !becomeActive {
                    terminationManager.addCleanupAction {
                        try? await server.shutdown()
                    }
                    
                    Task {
                        server = TimeCardServer(context: context)
                        try await server.run()
                    }
                    
                    becomeActive = true
                }
            }
    }
}

#Preview {
    ServerView()
}
