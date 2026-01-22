//
//  SystemUptimeRecordViewModel.swift
//  TimeCard
//
//  Created by uhimania on 2026/01/19.
//

import Foundation

class SystemUptimeRecordViewModel {
    private let repository: SystemUptimeRecordRepository
    
    init(repository: SystemUptimeRecordRepository) {
        self.repository = repository
    }
    
    func launch() {
        try? repository.launch()
    }
    
    func shutdown() {
        try? repository.shutdown()
    }
    
    func sleep() {
        try? repository.sleep()
    }
    
    func wake() {
        try? repository.wake()
    }
    
    func update() {
        try? repository.update()
    }
}
