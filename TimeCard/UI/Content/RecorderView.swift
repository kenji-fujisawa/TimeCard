//
//  RecorderView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/21.
//

import SwiftUI

struct RecorderView: View {
    let viewModel: TimeRecordViewModel
    
    var body: some View {
        VStack {
            ClockView()
            
            if viewModel.state == .offWork {
                Button {
                    viewModel.checkIn()
                } label: {
                    VStack {
                        Image(systemName: "play.desktopcomputer")
                            .font(.title)
                            .foregroundStyle(.cyan)
                            .padding(2)
                        Text("出勤")
                            .font(.caption)
                    }
                    .frame(width: 50, height: 50)
                }
                .accessibilityIdentifier("button_check_in")
            } else if viewModel.state == .atBreak {
                Button {
                    viewModel.endBreak()
                } label: {
                    VStack {
                        Image(systemName: "power.circle")
                            .font(.title)
                            .foregroundStyle(.orange)
                            .padding(2)
                        Text("休憩終了")
                            .font(.caption)
                    }
                    .frame(width: 50, height: 50)
                }
                .accessibilityIdentifier("button_break_end")
            } else if viewModel.state == .atWork {
                HStack {
                    Button {
                        viewModel.checkOut()
                    } label: {
                        VStack {
                            Image(systemName: "powersleep")
                                .font(.title)
                                .foregroundStyle(.yellow)
                                .padding(2)
                            Text("退勤")
                                .font(.caption)
                        }
                        .frame(width: 50, height: 50)
                    }
                    .accessibilityIdentifier("button_check_out")
                    
                    Button {
                        viewModel.startBreak()
                    } label: {
                        VStack {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.title)
                                .foregroundStyle(.purple)
                                .padding(2)
                            Text("休憩")
                                .font(.caption)
                        }
                        .frame(width: 50, height: 50)
                    }
                    .accessibilityIdentifier("button_break_start")
                }
            }
        }
    }
}

#Preview {
    let repository = FakeTimeRecordRepository()
    let viewModel = TimeRecordViewModel(repository)
    RecorderView(viewModel: viewModel)
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
