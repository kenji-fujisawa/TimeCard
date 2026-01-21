//
//  CalendarViewModel.swift
//  TimeCard
//
//  Created by uhimania on 2026/01/19.
//

import Foundation

class CalendarViewModel: ObservableObject {
    @Published var now: Date = .now
    @Published var records: [CalendarRecord] = []
    private let repository: CalendarRecordRepository
    private var fetchTask: Task<Void, Never>? = nil
    
    init(repository: CalendarRecordRepository) {
        self.repository = repository
        self.fetchRecords()
    }
    
    deinit {
        fetchTask?.cancel()
    }
    
    func fetchRecords() {
        let stream = repository.getRecords(year: now.year, month: now.month)
        
        fetchTask?.cancel()
        fetchTask = Task { [weak self] in
            for await records in stream {
                await MainActor.run { [weak self] in
                    self?.records = records
                }
            }
        }
    }
    
    func update(record: CalendarRecord) {
        try? repository.updateRecord(source: records, record: record)
    }
}
