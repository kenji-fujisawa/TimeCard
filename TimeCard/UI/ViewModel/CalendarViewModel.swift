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
    class CalendarRecord: Identifiable {
        @Observable
        class TimeRecord: Identifiable {
            @Observable
            class BreakTime: Identifiable {
                let start: Date?
                let end: Date?
                
                init(start: Date? = nil, end: Date? = nil) {
                    self.start = start
                    self.end = end
                }
            }
            
            let checkIn: Date?
            let checkOut: Date?
            let breakTimes: [BreakTime]
            let timeWorked: TimeInterval
            
            init(checkIn: Date? = nil, checkOut: Date? = nil, breakTimes: [BreakTime] = [], timeWorked: TimeInterval = 0) {
                self.checkIn = checkIn
                self.checkOut = checkOut
                self.breakTimes = breakTimes
                self.timeWorked = timeWorked
            }
        }
        
        let date: Date
        let timeRecords: [TimeRecord]
        let timeWorked: TimeInterval
        let systemUptime: TimeInterval
        
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
                    self?.records = records.map { $0.toViewModel() }
                    self?.timeWorkedSum = records.timeWorkedSum
                    self?.systemUptimeSum = records.systemUptimeSum
                }
            }
        }
    }
}

extension CalendarRecord {
    func toViewModel() -> CalendarViewModel.CalendarRecord {
        CalendarViewModel.CalendarRecord(
            date: self.date,
            timeRecords: self.timeRecords.map { $0.toViewModel() },
            timeWorked: self.timeWorked,
            systemUptime: self.systemUptime
        )
    }
}

extension TimeRecord {
    func toViewModel() -> CalendarViewModel.CalendarRecord.TimeRecord {
        CalendarViewModel.CalendarRecord.TimeRecord(
            checkIn: self.checkIn,
            checkOut: self.checkOut,
            breakTimes: self.breakTimes.map { $0.toViewModel() },
            timeWorked: self.timeWorked
        )
    }
}

extension TimeRecord.BreakTime {
    func toViewModel() -> CalendarViewModel.CalendarRecord.TimeRecord.BreakTime {
        CalendarViewModel.CalendarRecord.TimeRecord.BreakTime(
            start: self.start,
            end: self.end
        )
    }
}
