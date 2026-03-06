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
    class BreakTime: Identifiable, Equatable {
        var id: UUID
        var start: Date
        var end: Date
        
        init(id: UUID = UUID(), start: Date, end: Date) {
            self.id = id
            self.start = start
            self.end = end
        }
        
        static func == (lhs: TimeRecordEditViewModel.BreakTime, rhs: TimeRecordEditViewModel.BreakTime) -> Bool {
            lhs.id == rhs.id &&
            lhs.start == rhs.start &&
            lhs.end == rhs.end
        }
    }
    
    @Observable
    class TimeRecord: Identifiable, Equatable {
        var id: UUID
        var checkIn: Date
        var checkOut: Date
        var breakTimes: [BreakTime]
        var removeId: BreakTime.ID? = nil
        
        init(id: UUID = UUID(), checkIn: Date, checkOut: Date, breakTimes: [BreakTime] = []) {
            self.id = id
            self.checkIn = checkIn
            self.checkOut = checkOut
            self.breakTimes = breakTimes
        }
        
        func addBreakTime() {
            let breakTime = BreakTime(start: checkIn, end: checkIn)
            breakTimes.append(breakTime)
        }
        
        func removeBreakTime() {
            breakTimes.removeAll(where: { $0.id == removeId })
            removeId = nil
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
    var selectedId: TimeRecord.ID? = nil
    var removeId: TimeRecord.ID? = nil
    
    init(date: Date, records: [TimeRecord] = []) {
        self.date = date
        self.records = records
        self.selectedId = records.first?.id
    }
    
    func addRecord() {
        let record = TimeRecord(checkIn: date, checkOut: date)
        records.append(record)
        selectedId = record.id
    }
    
    func removeRecord() {
        records.removeAll(where: { $0.id == removeId })
        if selectedId == removeId {
            selectedId = records.first?.id
        }
        removeId = nil
    }
}

@Observable
class UptimeRecordEditViewModel {
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
        
        static func == (lhs: UptimeRecordEditViewModel.SleepRecord, rhs: UptimeRecordEditViewModel.SleepRecord) -> Bool {
            lhs.id == rhs.id &&
            lhs.start == rhs.start &&
            lhs.end == rhs.end
        }
    }
    
    @Observable
    class SystemUptimeRecord: Identifiable, Equatable {
        var id: UUID
        var launch: Date
        var shutdown: Date
        var sleepRecords: [SleepRecord]
        var removeId: SleepRecord.ID? = nil
        
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
        
        func addSleep() {
            let sleep = SleepRecord(start: launch, end: launch)
            sleepRecords.append(sleep)
        }
        
        func removeSleep() {
            sleepRecords.removeAll(where: { $0.id == removeId })
            removeId = nil
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
    var selectedId: SystemUptimeRecord.ID? = nil
    var removeId: SystemUptimeRecord.ID? = nil
    
    init(date: Date, records: [SystemUptimeRecord] = []) {
        self.date = date
        self.records = records
        self.selectedId = records.first?.id
    }
    
    func addRecord() {
        let record = SystemUptimeRecord(launch: date, shutdown: date)
        records.append(record)
        selectedId = record.id
    }
    
    func removeRecord() {
        records.removeAll(where: { $0.id == removeId })
        if selectedId == removeId {
            selectedId = records.first?.id
        }
        removeId = nil
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
    func toViewModel() -> TimeRecordEditViewModel.BreakTime {
        TimeRecordEditViewModel.BreakTime(
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
    func toViewModel() -> UptimeRecordEditViewModel.SleepRecord {
        UptimeRecordEditViewModel.SleepRecord(
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

extension TimeRecordEditViewModel.BreakTime {
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

extension UptimeRecordEditViewModel.SleepRecord {
    func toRecord() -> SystemUptimeRecord.SleepRecord {
        SystemUptimeRecord.SleepRecord(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}
