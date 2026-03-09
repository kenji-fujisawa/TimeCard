//
//  ContentView.swift
//  TimeCard
//
//  Created by uhimania on 2025/09/24.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.timeRecordRepository) private var repository
    
    var body: some View {
        VStack {
            RecorderView(viewModel: TimeRecordViewModel(repository))
            
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
    let repository = FakeTimeRecordRepository()
    ContentView()
        .environment(\.timeRecordRepository, repository)
}

private class FakeTimeRecordRepository: TimeRecordRepository {
    func getRecords(year: Int, month: Int) throws -> [TimeRecord] { [] }
    func getRecord(id: UUID) throws -> TimeRecord? { nil }
    func getBreakTime(id: UUID) throws -> TimeRecord.BreakTime? { nil }
    func insert(_ record: TimeRecord) throws {}
    func update(_ record: TimeRecord) throws {}
    func delete(_ record: TimeRecord) throws {}
    
    var state = WorkState.offWork
    func getState() -> WorkState {
        state
    }
    
    func checkIn() throws {
        state = .atWork
    }
    
    func checkOut() throws {
        state = .offWork
    }
    
    func startBreak() throws {
        state = .atBreak
    }
    
    func endBreak() throws {
        state = .atWork
    }
}
