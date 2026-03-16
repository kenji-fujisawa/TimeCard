//
//  CalendarViewModel.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2026/01/07.
//

import Foundation

@Observable
class CalendarViewModel {
    @Observable
    class BreakTime: Identifiable {
        let start: Date?
        let end: Date?
        
        var interval: TimeInterval {
            guard let start = start else { return 0 }
            guard let end = end else { return 0 }
            return end.timeIntervalSince(Calendar.current.startOfDay(for: start))
        }
        
        init(start: Date? = nil, end: Date? = nil) {
            self.start = start
            self.end = end
        }
    }
    
    @Observable
    class TimeRecord: Identifiable {
        let checkIn: Date?
        let checkOut: Date?
        let breakTimes: [BreakTime]
        
        var interval: TimeInterval {
            guard let checkIn = checkIn else { return 0 }
            guard let checkOut = checkOut else { return 0 }
            return checkOut.timeIntervalSince(Calendar.current.startOfDay(for: checkIn))
        }
        
        init(checkIn: Date? = nil, checkOut: Date? = nil, breakTimes: [BreakTime] = []) {
            self.checkIn = checkIn
            self.checkOut = checkOut
            self.breakTimes = breakTimes
        }
    }
    
    @Observable
    class CalendarRecord: Identifiable {
        let date: Date
        let records: [TimeRecord]
        
        init(date: Date, records: [TimeRecord] = []) {
            self.date = date
            self.records = records
        }
    }
    
    @ObservationIgnored private let repository: CalendarRecordRepository
    @ObservationIgnored private var fetchTask: Task<Void, Never>?
    
    var date: Date = .now
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
        
        let stream = repository.getRecordsStream(year: date.year, month: date.month)
        
        fetchTask?.cancel()
        fetchTask = Task { [weak self] in
            do {
                for try await records in stream {
                    await MainActor.run { [weak self] in
                        self?.records = records.map { $0.asViewModel() }
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
}

extension CalendarRecord {
    func asViewModel() -> CalendarViewModel.CalendarRecord {
        CalendarViewModel.CalendarRecord(
            date: self.date,
            records: self.records.map { $0.asViewModel() }
        )
    }
}

extension TimeRecord {
    func asViewModel() -> CalendarViewModel.TimeRecord {
        CalendarViewModel.TimeRecord(
            checkIn: self.checkIn,
            checkOut: self.checkOut,
            breakTimes: self.breakTimes.map { $0.asViewModel() }
        )
    }
}

extension TimeRecord.BreakTime {
    func asViewModel() -> CalendarViewModel.BreakTime {
        CalendarViewModel.BreakTime(
            start: self.start,
            end: self.end
        )
    }
}
