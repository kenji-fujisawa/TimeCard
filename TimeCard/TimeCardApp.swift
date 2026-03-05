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
    private let timeRepository: TimeRecordRepository
    private let uptimeRepository: SystemUptimeRecordRepository
    private let calendarRepository: CalendarRecordRepository
    
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
        
        let source = DefaultLocalDataSource(container.mainContext)
        timeRepository = DefaultTimeRecordRepository(source)
        uptimeRepository = DefaultSystemUptimeRecordRepository(source)
        calendarRepository = DefaultCalendarRecordRepository(source)
    }
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environment(\.timeRecordRepository, timeRepository)
                .onReceive(NotificationCenter.default.publisher(for: Notification.exitApp)) { _ in
                    Task {
                        await AppTerminationManager.shared.performCleanup()
                        NSApplication.shared.terminate(nil)
                    }
                }
        } label: {
            Image(systemName: "clock.badge.checkmark")
            SystemUptimeView(viewModel: SystemUptimeRecordViewModel(uptimeRepository))
            SleepView(viewModel: TimeRecordViewModel(timeRepository))
            ServerView(server: TimeCardServer(timeRepository))
        }
        .menuBarExtraStyle(.window)
        
        Window("TimeCard", id: "calendar") {
            CalendarView(viewModel: CalendarViewModel(calendarRepository))
        }
        
        Settings {
            LaunchSettingView()
        }
    }
}

extension Notification {
    static let exitApp = Notification.Name("exitApp")
}

class AppTerminationManager {
    private var cleanupActions: [() async -> Void] = []
    
    static let shared = AppTerminationManager()
    
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

extension EnvironmentValues {
    @Entry var terminationManager = AppTerminationManager.shared
    @Entry var timeRecordRepository: TimeRecordRepository = FakeTimeRecordRepository()
}

private class FakeTimeRecordRepository: TimeRecordRepository {
    func getRecords(year: Int, month: Int) throws -> [TimeRecord] { [] }
    func getRecord(id: UUID) throws -> TimeRecord? { nil }
    func getBreakTime(id: UUID) throws -> TimeRecord.BreakTime? { nil }
    func insert(_ record: TimeRecord) throws {}
    func update(_ record: TimeRecord) throws {}
    func delete(_ record: TimeRecord) throws {}
    func getState() -> WorkState { .offWork }
    func checkIn() throws {}
    func checkOut() throws {}
    func startBreak() throws {}
    func endBreak() throws {}
}

#if DEBUG
struct UITestApp: App {
    private let container: ModelContainer
    @State private var timeViewModel: TimeRecordViewModel
    private let uptimeViewModel: SystemUptimeRecordViewModel
    @State private var calendarViewModel: CalendarViewModel
    private let formatter: DateFormatter
    @State private var record: CalendarRecord
    @State private var recordToEdit: CalendarRecord? = nil
    @State private var now: Date
    @State private var uptime: SystemUptimeRecord? = nil
    
    init() {
        let schema = Schema(versionedSchema: TimeCardSchema_v3.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            try container = ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError(error.localizedDescription)
        }
        
        let source = DefaultLocalDataSource(container.mainContext)
        let timeRepository = DefaultTimeRecordRepository(source)
        timeViewModel = TimeRecordViewModel(timeRepository)
        
        let uptimeRepository = DefaultSystemUptimeRecordRepository(source)
        uptimeViewModel = SystemUptimeRecordViewModel(uptimeRepository)
        
        let calendarRepository = DefaultCalendarRecordRepository(source)
        calendarViewModel = CalendarViewModel(calendarRepository)
        
        formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        record = CalendarRecord(
            date: formatter.date(from: "2025-12-29 00:00:00") ?? .now,
            timeRecords: [
                TimeRecord(
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
            uptimeRecords: [
                SystemUptimeRecord(
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
                RecorderView(viewModel: timeViewModel)
            } else if CommandLine.arguments.contains("CalendarViewTests") {
                RecorderView(viewModel: timeViewModel)
                CalendarView(viewModel: calendarViewModel)
            } else if CommandLine.arguments.contains("CalendarRecordViewTests") {
                CalendarRecordView(record: record, fixed: true, recordToEdit: $recordToEdit)
                if let rec = recordToEdit {
                    Text(rec.date, format: .dateTime.month().day())
                        .accessibilityIdentifier("text_rec_to_edit")
                }
            } else if CommandLine.arguments.contains("MonthSelectorViewTests") {
                MonthSelectorView(date: $now)
            } else if CommandLine.arguments.contains("RecordEditViewTests") {
                Text("\(calendarViewModel.records.first?.timeRecords.count ?? 0)")
                    .accessibilityIdentifier("time_record_count")
                Text("\(calendarViewModel.records.first?.uptimeRecords.count ?? 0)")
                    .accessibilityIdentifier("uptime_record_count")
                Button("show") {
                    recordToEdit = calendarViewModel.records.first
                }
                .sheet(item: $recordToEdit) { record in
                    RecordEditView(record: record, viewModel: calendarViewModel)
                }
            } else if CommandLine.arguments.contains("TimeRecordEditViewTests") {
                TimeRecordEditView(record: $record)
                    .modelContainer(for: LocalTimeRecord.self, inMemory: true)
            } else if CommandLine.arguments.contains("SystemUptimeRecordEditViewTests") {
                SystemUptimeRecordEditView(record: $record)
                    .modelContainer(for: LocalUptimeRecord.self, inMemory: true)
            } else if CommandLine.arguments.contains("SleepViewTests") {
                SleepView(viewModel: timeViewModel)
                Text("\(String(describing: timeViewModel.state))")
                    .accessibilityIdentifier("state")
                Button("checkIn") {
                    timeViewModel.checkIn()
                }
                Button("sleep") {
                    NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.willSleepNotification, object: nil)
                }
                Button("wake") {
                    NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil)
                }
            } else if CommandLine.arguments.contains("SystemUptimeViewTests") {
                SystemUptimeView(viewModel: uptimeViewModel)
                if let uptime = self.uptime {
                    Text(uptime.launch, format: .dateTime.hour().minute().second())
                        .accessibilityIdentifier("launch")
                    Text(uptime.shutdown, format: .dateTime.hour().minute().second())
                        .accessibilityIdentifier("shutdown")
                    if let sleep = uptime.sleepRecords.first {
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
                        await AppTerminationManager.shared.performCleanup()
                    }
                }
                Button("update") {
                    let descriptor = FetchDescriptor<LocalUptimeRecord>(
                        sortBy: [.init(\.launch)]
                    )
                    self.uptime = try? container.mainContext.fetch(descriptor).first?.toUptimeRecord()
                }
            }
        }
    }
}
#endif
