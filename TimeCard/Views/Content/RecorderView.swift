//
//  RecorderView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/21.
//

import SwiftUI

struct RecorderView: View {
    @ObservedObject var model: TimeRecordViewModel
    
    var body: some View {
        VStack {
            ClockView()
            
            if model.state == .OffWork {
                Button {
                    model.checkIn()
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
            } else if model.state == .AtBreak {
                Button {
                    model.endBreak()
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
            } else if model.state == .AtWork {
                HStack {
                    Button {
                        model.checkOut()
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
                        model.startBreak()
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
    let model = TimeRecordViewModel(repository: repository)
    RecorderView(model: model)
}

private class FakeTimeRecordRepository: TimeRecordRepository {
    var state = WorkState.OffWork
    func getState() -> WorkState {
        state
    }
    
    func checkIn() throws {
        state = .AtWork
    }
    
    func checkOut() throws {
        state = .OffWork
    }
    
    func startBreak() throws {
        state = .AtBreak
    }
    
    func endBreak() throws {
        state = .AtWork
    }
}
