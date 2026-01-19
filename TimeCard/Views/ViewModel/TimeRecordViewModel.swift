//
//  TimeRecordViewModel.swift
//  TimeCard
//
//  Created by uhimania on 2026/01/14.
//

import Foundation

class TimeRecordViewModel: ObservableObject {
    private let repository: TimeRecordRepository
    
    @Published var state: WorkState
    
    init(repository: TimeRecordRepository) {
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
