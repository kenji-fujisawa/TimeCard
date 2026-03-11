//
//  CalendarViewModel.swift
//  TimeCard
//
//  Created by uhimania on 2026/01/19.
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
        let timeWorked: TimeInterval
        
        var interval: TimeInterval {
            guard let checkIn = checkIn else { return 0 }
            guard let checkOut = checkOut else { return 0 }
            return checkOut.timeIntervalSince(Calendar.current.startOfDay(for: checkIn))
        }
        
        init(checkIn: Date? = nil, checkOut: Date? = nil, breakTimes: [BreakTime] = [], timeWorked: TimeInterval = 0) {
            self.checkIn = checkIn
            self.checkOut = checkOut
            self.breakTimes = breakTimes
            self.timeWorked = timeWorked
        }
    }
    
    @Observable
    class CalendarRecord: Identifiable {
        let date: Date
        let timeRecords: [TimeRecord]
        let timeWorked: TimeInterval
        let systemUptime: TimeInterval
        
        var fixed: Bool {
            let now = Date.now
            if date.year == now.year && date.month == now.month && date.day == now.day {
                let latest = timeRecords.last
                return latest != nil && latest?.checkIn != nil && latest?.checkOut != nil
            }
            
            return date < now
        }
        
        init(date: Date, timeRecords: [TimeRecord] = [], timeWorked: TimeInterval = 0, systemUptime: TimeInterval = 0) {
            self.date = date
            self.timeRecords = timeRecords
            self.timeWorked = timeWorked
            self.systemUptime = systemUptime
        }
    }
    
    @ObservationIgnored private let repository: CalendarRecordRepository
    @ObservationIgnored private var fetchTask: Task<Void, Never>? = nil
    
    var date: Date = .now
    var records: [CalendarRecord] = []
    private(set) var timeWorkedSum: TimeInterval = 0
    private(set) var systemUptimeSum: TimeInterval = 0
    
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
                    self?.records = records.map { $0.asViewModel() }
                    self?.timeWorkedSum = records.timeWorkedSum
                    self?.systemUptimeSum = records.systemUptimeSum
                }
            }
        }
    }
}

extension CalendarRecord {
    func asViewModel() -> CalendarViewModel.CalendarRecord {
        CalendarViewModel.CalendarRecord(
            date: self.date,
            timeRecords: self.timeRecords.map { $0.asViewModel() },
            timeWorked: self.timeWorked,
            systemUptime: self.systemUptime
        )
    }
}

extension TimeRecord {
    func asViewModel() -> CalendarViewModel.TimeRecord {
        CalendarViewModel.TimeRecord(
            checkIn: self.checkIn,
            checkOut: self.checkOut,
            breakTimes: self.breakTimes.map { $0.asViewModel() },
            timeWorked: self.timeWorked
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
