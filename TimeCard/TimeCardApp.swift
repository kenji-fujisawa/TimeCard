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
    private let timeRecord: TimeRecordViewModel
    private let uptimeRecord: SystemUptimeRecordViewModel
    private let calendar: CalendarViewModel
    
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
        
        let source = DefaultLocalDataSource(context: container.mainContext)
        let timeRepository = DefaultTimeRecordRepository(source: source)
        timeRecord = TimeRecordViewModel(repository: timeRepository)
        
        let uptimeRepository = DefaultSystemUptimeRecordRepository(source: source)
        uptimeRecord = SystemUptimeRecordViewModel(repository: uptimeRepository)
        
        let calendarRepository = DefaultCalendarRecordRepository(source: source)
        calendar = CalendarViewModel(repository: calendarRepository)
    }
    
    var body: some Scene {
        MenuBarExtra {
            ContentView(timeRecord: timeRecord)
                .onReceive(NotificationCenter.default.publisher(for: Notification.exitApp)) { _ in
                    Task {
                        await terminationManager.performCleanup()
                        NSApplication.shared.terminate(nil)
                    }
                }
        } label: {
            Image(systemName: "clock.badge.checkmark")
            SystemUptimeView(uptimeRecord: uptimeRecord)
                .environmentObject(terminationManager)
            SleepView(timeRecord: timeRecord)
            ServerView()
                .modelContainer(container)
                .environmentObject(terminationManager)
        }
        .menuBarExtraStyle(.window)
        
        Window("TimeCard", id: "calendar") {
            CalendarView(calendar: calendar)
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
    private let container: ModelContainer
    @StateObject private var timeRecord: TimeRecordViewModel
    private let uptimeRecord: SystemUptimeRecordViewModel
    @StateObject private var calendar: CalendarViewModel
    private let formatter: DateFormatter
    @State private var record: CalendarRecord
    @State private var recordToEdit: CalendarRecord? = nil
    @State private var now: Date
    @State private var uptime: SystemUptimeRecord? = nil
    private let terminationManager = AppTerminationManager()
    
    init() {
        let schema = Schema(versionedSchema: TimeCardSchema_v3.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            try container = ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError(error.localizedDescription)
        }
        
        let source = DefaultLocalDataSource(context: container.mainContext)
        let timeRepository = DefaultTimeRecordRepository(source: source)
        let timeRecord = TimeRecordViewModel(repository: timeRepository)
        _timeRecord = StateObject(wrappedValue: timeRecord)
        
        let uptimeRepository = DefaultSystemUptimeRecordRepository(source: source)
        uptimeRecord = SystemUptimeRecordViewModel(repository: uptimeRepository)
        
        let calendarRepository = DefaultCalendarRecordRepository(source: source)
        let calendar = CalendarViewModel(repository: calendarRepository)
        _calendar = StateObject(wrappedValue: calendar)
        
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
                RecorderView(model: timeRecord)
            } else if CommandLine.arguments.contains("CalendarViewTests") {
                RecorderView(model: timeRecord)
                CalendarView(calendar: calendar)
            } else if CommandLine.arguments.contains("CalendarRecordViewTests") {
                CalendarRecordView(record: record, fixed: true, recordToEdit: $recordToEdit)
                if let rec = recordToEdit {
                    Text(rec.date, format: .dateTime.month().day())
                        .accessibilityIdentifier("text_rec_to_edit")
                }
            } else if CommandLine.arguments.contains("MonthSelectorViewTests") {
                MonthSelectorView(now: $now)
            } else if CommandLine.arguments.contains("RecordEditViewTests") {
                Text("\(calendar.records.first?.records.count ?? 0)")
                    .accessibilityIdentifier("time_record_count")
                Text("\(calendar.records.first?.systemUptimeRecords.count ?? 0)")
                    .accessibilityIdentifier("uptime_record_count")
                Button("show") {
                    recordToEdit = calendar.records.first
                }
                .sheet(item: $recordToEdit) { record in
                    RecordEditView(record: record, calendar: calendar)
                }
            } else if CommandLine.arguments.contains("TimeRecordEditViewTests") {
                TimeRecordEditView(record: $record)
                    .modelContainer(for: TimeRecord.self, inMemory: true)
            } else if CommandLine.arguments.contains("SystemUptimeRecordEditViewTests") {
                SystemUptimeRecordEditView(record: $record)
                    .modelContainer(for: SystemUptimeRecord.self, inMemory: true)
            } else if CommandLine.arguments.contains("SleepViewTests") {
                SleepView(timeRecord: timeRecord)
                Text("\(String(describing: timeRecord.state))")
                    .accessibilityIdentifier("state")
                Button("checkIn") {
                    timeRecord.checkIn()
                }
                Button("sleep") {
                    NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.willSleepNotification, object: nil)
                }
                Button("wake") {
                    NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil)
                }
            } else if CommandLine.arguments.contains("SystemUptimeViewTests") {
                SystemUptimeView(uptimeRecord: uptimeRecord)
                    .environmentObject(terminationManager)
                if let uptime = self.uptime {
                    Text(uptime.launch, format: .dateTime.hour().minute().second())
                        .accessibilityIdentifier("launch")
                    Text(uptime.shutdown, format: .dateTime.hour().minute().second())
                        .accessibilityIdentifier("shutdown")
                    if let sleep = uptime.sortedSleepRecords.first {
                        Text(sleep.start, format: .dateTime.hour().minute().second())
                            .accessibilityIdentifier("start")
                        Text(sleep.end, format: .dateTime.hour().minute().second())
                            .accessibilityIdentifier("end")
                    }
                }
                Button("sleep") {
                    NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.willSleepNotification, object: nil)
                }
                Button("wake") {
                    NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil)
                }
                Button("terminate") {
                    Task {
                        await terminationManager.performCleanup()
                    }
                }
                Button("update") {
                    let descriptor = FetchDescriptor<SystemUptimeRecord>(
                        sortBy: [.init(\.launch)]
                    )
                    self.uptime = try? container.mainContext.fetch(descriptor).first
                }
            }
        }
    }
}
#endif
