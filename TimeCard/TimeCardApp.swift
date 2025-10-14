//
//  TimeCardApp.swift
//  TimeCard
//
//  Created by uhimania on 2025/09/24.
//

import SwiftData
import SwiftUI

@main
struct TimeCardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: TimeRecord.self)
        }
        .commands {
            CommandGroup(replacing: .pasteboard) {}
            CommandGroup(replacing: .undoRedo) {}
            ExportPDFCommands()
        }
    }
}
