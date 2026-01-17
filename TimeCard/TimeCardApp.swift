//
//  TimeCardApp.swift
//  TimeCard
//
//  Created by uhimania on 2025/09/24.
//

import SwiftData
import SwiftUI

struct TimeCardApp: App {
    private var container: ModelContainer
    private let terminationManager = AppTerminationManager()
    
    init() {
        #if DEBUG
        let inMemory = true
        #else
        let inMemory = false
        #endif
        let schema = Schema(versionedSchema: TimeCardSchema_v3.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            try container = ModelContainer(for: schema, migrationPlan: TimeCardMigrationPlan.self, configurations: [config])
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .modelContainer(container)
                .onReceive(NotificationCenter.default.publisher(for: Notification.exitApp)) { _ in
                    Task {
                        await terminationManager.performCleanup()
                        NSApplication.shared.terminate(nil)
                    }
                }
        } label: {
            Image(systemName: "clock.badge.checkmark")
            SystemUptimeView()
                .modelContainer(container)
                .environmentObject(terminationManager)
            SleepView()
                .modelContainer(container)
            ServerView()
                .modelContainer(container)
                .environmentObject(terminationManager)
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

extension Notification {
    static let exitApp = Notification.Name("exitApp")
}

class AppTerminationManager: ObservableObject {
    private var cleanupActions: [() async -> Void] = []
    
    func addCleanupAction(_ action: @escaping () async -> Void) {
        cleanupActions.append(action)
    }
    
    func performCleanup() async {
        await withTaskGroup(of: Void.self) { group in
            for action in cleanupActions {
                group.addTask {
                    await action()
                }
            }
        }
    }
}

#if DEBUG
struct UITestApp: App {
    private let formatter: DateFormatter
    private let record: CalendarRecord
    @State private var recordToEdit: CalendarRecord? = nil
    @State private var now: Date
    
    init() {
        formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        record = CalendarRecord(
            date: formatter.date(from: "2025-12-29 00:00:00") ?? .now,
            records: [
                TimeRecord(
                    year: 2025,
                    month: 12,
                    checkIn: formatter.date(from: "2025-12-29 09:45:30"),
                    checkOut: formatter.date(from: "2025-12-30 02:12:38"),
                    breakTimes: [
                        TimeRecord.BreakTime(
                            start: formatter.date(from: "2025-12-29 23:48:12"),
                            end: formatter.date(from: "2025-12-30 01:33:48")
                        )
                    ]
                )
            ],
            systemUptimeRecords: [
                SystemUptimeRecord(
                    year: 2025,
                    month: 12,
                    day: 29,
                    launch: formatter.date(from: "2025-12-29 08:27:32") ?? .now,
                    shutdown: formatter.date(from: "2025-12-29 23:59:58") ?? .now,
                    sleepRecords: [
                        SystemUptimeRecord.SleepRecord(
                            start: formatter.date(from: "2025-12-29 12:30:20") ?? .now,
                            end: formatter.date(from: "2025-12-29 13:15:18") ?? .now
                        )
                    ]
                )
            ]
        )
        
        now = formatter.date(from: "2025-12-29 00:00:00") ?? .now
    }
    
    var body: some Scene {
        WindowGroup {
            if CommandLine.arguments.contains("RecorderViewTests") {
                RecorderView()
                    .modelContainer(for: TimeRecord.self, inMemory: true)
            }
            else if CommandLine.arguments.contains("CalendarRecordViewTests") {
                CalendarRecordView(record: record, fixed: true, recordToEdit: $recordToEdit)
                if let rec = recordToEdit {
                    Text(rec.date, format: .dateTime.month().day())
                        .accessibilityIdentifier("text_rec_to_edit")
                }
            }
            else if CommandLine.arguments.contains("MonthSelectorViewTests") {
                MonthSelectorView(now: $now)
            }
            else if CommandLine.arguments.contains("TimeRecordEditViewTests") {
                TimeRecordEditView(record: record)
                    .modelContainer(for: TimeRecord.self, inMemory: true)
            }
            else if CommandLine.arguments.contains("SystemUptimeRecordEditViewTests") {
                SystemUptimeRecordEditView(record: record)
                    .modelContainer(for: SystemUptimeRecord.self, inMemory: true)
            }
        }
    }
}
#endif
