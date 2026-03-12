//
//  CalendarViewModel.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2026/01/07.
//

import Foundation

@Observable
class CalendarViewModel {
    @ObservationIgnored private let repository: CalendarRecordRepository
    @ObservationIgnored private var fetchTask: Task<Void, Never>?
    
    var now: Date = .now
    var records: [CalendarRecord] = []
    var loading: Bool = false
    var message: String = ""
    
    init(_ repository: CalendarRecordRepository) {
        self.repository = repository
        fetchRecords()
    }
    
    deinit {
        fetchTask?.cancel()
    }
    
    func fetchRecords() {
        self.loading = true
        
        let stream = repository.getRecordsStream(year: now.year, month: now.month)
        
        fetchTask?.cancel()
        fetchTask = Task { [weak self] in
            do {
                for try await records in stream {
                    await MainActor.run { [weak self] in
                        self?.records = records
                        self?.loading = false
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.message = "データを取得できませんでした"
                    self?.loading = false
                }
            }
        }
    }
    
    func updateRecord(_ record: CalendarRecord) {
        Task {
            do {
                try await repository.updateRecord(record)
            } catch {
                await MainActor.run {
                    self.message = "更新に失敗しました"
                }
            }
        }
    }
}
