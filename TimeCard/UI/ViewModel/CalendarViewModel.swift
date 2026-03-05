//
//  CalendarViewModel.swift
//  TimeCard
//
//  Created by uhimania on 2026/01/19.
//

import Foundation

@Observable
class CalendarViewModel {
    @ObservationIgnored private let repository: CalendarRecordRepository
    @ObservationIgnored private var fetchTask: Task<Void, Never>? = nil
    
    var date: Date = .now
    var records: [CalendarRecord] = []
    
    init(_ repository: CalendarRecordRepository) {
        self.repository = repository
        self.fetchRecords()
    }
    
    deinit {
        fetchTask?.cancel()
    }
    
    func fetchRecords() {
        let stream = repository.getRecordsStream(year: date.year, month: date.month)
        
        fetchTask?.cancel()
        fetchTask = Task { [weak self] in
            for await records in stream {
                await MainActor.run { [weak self] in
                    self?.records = records
                }
            }
        }
    }
}
