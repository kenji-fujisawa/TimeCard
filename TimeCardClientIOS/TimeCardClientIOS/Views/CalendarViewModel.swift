//
//  CalendarViewModel.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2026/01/07.
//

import Foundation

class CalendarViewModel: ObservableObject {
    @Published var now: Date = .now
    @Published var records: [CalendarRecord] = []
    @Published var loading: Bool = false
    @Published var message: String = ""
    private let repository: CalendarRecordRepository
    private var fetchTask: Task<Void, Never>?
    
    init(repository: CalendarRecordRepository) {
        self.repository = repository
        fetchRecords()
    }
    
    deinit {
        fetchTask?.cancel()
    }
    
    func fetchRecords() {
        self.loading = true
        
        let stream = repository.getRecords(year: now.year, month: now.month)
        
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
    
    func updateRecord(record: CalendarRecord) {
        Task {
            do {
                try await repository.updateRecord(source: records, record: record)
            } catch {
                await MainActor.run {
                    self.message = "更新に失敗しました"
                }
            }
        }
    }
}
