//
//  TimeRecordViewModel.swift
//  TimeCard
//
//  Created by uhimania on 2026/01/14.
//

import Foundation

@Observable
class TimeRecordViewModel {
    @ObservationIgnored private let repository: TimeRecordRepository
    
    var state: WorkState
    
    init(_ repository: TimeRecordRepository) {
        self.repository = repository
        self.state = repository.getState()
    }
    
    func checkIn() {
        try? repository.checkIn()
        state = repository.getState()
    }
    
    func checkOut() {
        try? repository.checkOut()
        state = repository.getState()
    }
    
    func startBreak() {
        try? repository.startBreak()
        state = repository.getState()
    }
    
    func endBreak() {
        try? repository.endBreak()
        state = repository.getState()
    }
}
