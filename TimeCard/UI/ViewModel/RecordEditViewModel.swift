//
//  RecordEditViewModel.swift
//  TimeCard
//
//  Created by uhimania on 2026/03/04.
//

import Foundation

@Observable
class RecordEditViewModel {
    @ObservationIgnored private let repository: CalendarRecordRepository
    
    var timeViewModel: TimeRecordEditViewModel
    var uptimeViewModel: UptimeRecordEditViewModel
    
    init(_ repository: CalendarRecordRepository, _ date: Date) {
        self.repository = repository
        self.timeViewModel = TimeRecordEditViewModel(date: date)
        self.uptimeViewModel = UptimeRecordEditViewModel(date: date)
        
        if let record = try? repository.getRecord(year: date.year, month: date.month, day: date.day) {
            self.timeViewModel.records = record.timeRecords.map { $0.toViewModel() }
            self.uptimeViewModel.records = record.uptimeRecords.map { $0.toViewModel() }
        }
    }
    
    func update() {
        let record = CalendarRecord(
            date: timeViewModel.date,
            timeRecords: timeViewModel.records.map { $0.toRecord() },
            uptimeRecords: uptimeViewModel.records.map { $0.toRecord() }
        )
        try? repository.updateRecord(record)
    }
}

@Observable
class TimeRecordEditViewModel {
    @Observable
    class TimeRecord: Identifiable, Equatable {
        @Observable
        class BreakTime: Identifiable, Equatable {
            var id: UUID
            var start: Date
            var end: Date
            
            init(id: UUID = UUID(), start: Date, end: Date) {
                self.id = id
                self.start = start
                self.end = end
            }
            
            static func == (lhs: TimeRecordEditViewModel.TimeRecord.BreakTime, rhs: TimeRecordEditViewModel.TimeRecord.BreakTime) -> Bool {
                lhs.id == rhs.id &&
                lhs.start == rhs.start &&
                lhs.end == rhs.end
            }
        }
        
        var id: UUID
        var checkIn: Date
        var checkOut: Date
        var breakTimes: [BreakTime]
        
        init(id: UUID = UUID(), checkIn: Date, checkOut: Date, breakTimes: [BreakTime] = []) {
            self.id = id
            self.checkIn = checkIn
            self.checkOut = checkOut
            self.breakTimes = breakTimes
        }
        
        static func == (lhs: TimeRecordEditViewModel.TimeRecord, rhs: TimeRecordEditViewModel.TimeRecord) -> Bool {
            lhs.id == rhs.id &&
            lhs.checkIn == rhs.checkIn &&
            lhs.checkOut == rhs.checkOut &&
            lhs.breakTimes == rhs.breakTimes
        }
    }
    
    var date: Date
    var records: [TimeRecord] = []
    
    init(date: Date, records: [TimeRecord] = []) {
        self.date = date
        self.records = records
    }
}

@Observable
class UptimeRecordEditViewModel {
    @Observable
    class SystemUptimeRecord: Identifiable, Equatable {
        @Observable
        class SleepRecord: Identifiable, Equatable {
            var id: UUID
            var start: Date
            var end: Date
            
            init(id: UUID = UUID(), start: Date, end: Date) {
                self.id = id
                self.start = start
                self.end = end
            }
            
            static func == (lhs: UptimeRecordEditViewModel.SystemUptimeRecord.SleepRecord, rhs: UptimeRecordEditViewModel.SystemUptimeRecord.SleepRecord) -> Bool {
                lhs.id == rhs.id &&
                lhs.start == rhs.start &&
                lhs.end == rhs.end
            }
        }
        
        var id: UUID
        var launch: Date
        var shutdown: Date
        var sleepRecords: [SleepRecord]
        
        var uptime: TimeInterval {
            var interval = shutdown.timeIntervalSince(launch)
            for sleep in self.sleepRecords {
                interval -= sleep.end.timeIntervalSince(sleep.start)
            }
            
            return interval
        }
        
        init(id: UUID = UUID(), launch: Date, shutdown: Date, sleepRecords: [SleepRecord] = []) {
            self.id = id
            self.launch = launch
            self.shutdown = shutdown
            self.sleepRecords = sleepRecords
        }
        
        static func == (lhs: UptimeRecordEditViewModel.SystemUptimeRecord, rhs: UptimeRecordEditViewModel.SystemUptimeRecord) -> Bool {
            lhs.id == rhs.id &&
            lhs.launch == rhs.launch &&
            lhs.shutdown == rhs.shutdown &&
            lhs.sleepRecords == rhs.sleepRecords
        }
    }
    
    var date: Date
    var records: [SystemUptimeRecord] = []
    
    init(date: Date, records: [SystemUptimeRecord] = []) {
        self.date = date
        self.records = records
    }
}

extension TimeRecord {
    func toViewModel() -> TimeRecordEditViewModel.TimeRecord {
        TimeRecordEditViewModel.TimeRecord(
            id: self.id,
            checkIn: self.checkIn ?? .now,
            checkOut: self.checkOut ?? .now,
            breakTimes: self.breakTimes.map { $0.toViewModel() }
        )
    }
}

extension TimeRecord.BreakTime {
    func toViewModel() -> TimeRecordEditViewModel.TimeRecord.BreakTime {
        TimeRecordEditViewModel.TimeRecord.BreakTime(
            id: self.id,
            start: self.start ?? .now,
            end: self.end ?? .now
        )
    }
}

extension SystemUptimeRecord {
    func toViewModel() -> UptimeRecordEditViewModel.SystemUptimeRecord {
        UptimeRecordEditViewModel.SystemUptimeRecord(
            id: self.id,
            launch: self.launch,
            shutdown: self.shutdown,
            sleepRecords: self.sleepRecords.map { $0.toViewModel() }
        )
    }
}

extension SystemUptimeRecord.SleepRecord {
    func toViewModel() -> UptimeRecordEditViewModel.SystemUptimeRecord.SleepRecord {
        UptimeRecordEditViewModel.SystemUptimeRecord.SleepRecord(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}

extension TimeRecordEditViewModel.TimeRecord {
    func toRecord() -> TimeRecord {
        TimeRecord(
            id: self.id,
            checkIn: self.checkIn,
            checkOut: self.checkOut,
            breakTimes: self.breakTimes.map { $0.toBreakTime() }
        )
    }
}

extension TimeRecordEditViewModel.TimeRecord.BreakTime {
    func toBreakTime() -> TimeRecord.BreakTime {
        TimeRecord.BreakTime(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}

extension UptimeRecordEditViewModel.SystemUptimeRecord {
    func toRecord() -> SystemUptimeRecord {
        SystemUptimeRecord(
            id: self.id,
            launch: self.launch,
            shutdown: self.shutdown,
            sleepRecords: self.sleepRecords.map { $0.toRecord() }
        )
    }
}

extension UptimeRecordEditViewModel.SystemUptimeRecord.SleepRecord {
    func toRecord() -> SystemUptimeRecord.SleepRecord {
        SystemUptimeRecord.SleepRecord(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}
