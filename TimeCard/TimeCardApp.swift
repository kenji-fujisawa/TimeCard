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
    private var container: ModelContainer
    
    init() {
        #if DEBUG
        let inMemory = true
        #else
        let inMemory = false
        #endif
        let schema = Schema([TimeRecord.self, SystemUptimeRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            try container = ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .modelContainer(container)
        } label: {
            Image(systemName: "clock.badge.checkmark.fill")
            SystemUptimeView()
                .modelContainer(container)
        }
        .menuBarExtraStyle(.window)
        
        Window("TimeCard", id: "calendar") {
            CalendarView()
                .modelContainer(container)
        }
        
        Settings {
            LaunchSettingView()
        }
    }
}
