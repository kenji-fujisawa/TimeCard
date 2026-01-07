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
    
    init(repository: CalendarRecordRepository) {
        self.repository = repository
        fetchRecords()
    }
    
    func fetchRecords() {
        self.loading = true
        
        Task {
            let records: [CalendarRecord]
            let message: String
            
            do {
                records = try await repository.getRecords(year: now.year, month: now.month)
                message = ""
            } catch {
                records = Calendar.current.datesOf(year: now.year, month: now.month).map { date in
                    CalendarRecord(date: date, records: [])
                }
                message = "データを取得できませんでした"
            }
            
            await MainActor.run {
                self.records = records
                self.message = message
                self.loading = false
            }
        }
    }
    
    func updateRecord(record: CalendarRecord) {
        Task {
            do {
                let records = try await repository.updateRecord(source: records, record: record)
                await MainActor.run {
                    self.records = records
                }
            } catch {
                await MainActor.run {
                    self.message = "更新に失敗しました"
                }
            }
        }
    }
}
