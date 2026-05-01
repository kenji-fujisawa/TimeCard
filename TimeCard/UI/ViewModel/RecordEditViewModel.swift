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
    @ObservationIgnored private let date: Date
    @ObservationIgnored private var timeRecords: [TimeRecordEditViewModel.TimeRecord] = []
    @ObservationIgnored private var uptimeRecords: [UptimeRecordEditViewModel.SystemUptimeRecord] = []
    
    var timeViewModel: TimeRecordEditViewModel
    var uptimeViewModel: UptimeRecordEditViewModel
    
    init(_ repository: CalendarRecordRepository, _ date: Date) {
        self.repository = repository
        self.date = date
        self.timeViewModel = TimeRecordEditViewModel(date: date)
        self.uptimeViewModel = UptimeRecordEditViewModel(date: date)
        
        if let record = try? repository.getRecord(year: date.year, month: date.month, day: date.day) {
            self.timeViewModel.records = record.timeRecords.map { $0.asViewModel() }
            self.timeViewModel.selectedId = record.timeRecords.first?.id
            self.uptimeViewModel.records = record.uptimeRecords.map { $0.asViewModel() }
            self.uptimeViewModel.selectedId = record.uptimeRecords.first?.id
            
            self.timeRecords = self.timeViewModel.records.copy()
            self.uptimeRecords = self.uptimeViewModel.records.copy()
        }
    }
    
    func update() {
        let record = CalendarRecord(
            date: date,
            timeRecords: timeViewModel.records.map { $0.asRecord() },
            uptimeRecords: uptimeViewModel.records.map { $0.asRecord() }
        )
        try? repository.updateRecord(record)
        
        timeRecords = timeViewModel.records.copy()
        uptimeRecords = uptimeViewModel.records.copy()
    }
    
    func isValid() -> Bool {
        if !timeViewModel.isValid() || !uptimeViewModel.isValid() { return false }
        
        return timeRecords != timeViewModel.records || uptimeRecords != uptimeViewModel.records
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
        var editable: Bool
        var removeId: BreakTime.ID? = nil
        
        init(id: UUID = UUID(), checkIn: Date, checkOut: Date, breakTimes: [BreakTime] = [], editable: Bool = true) {
            self.id = id
            self.checkIn = checkIn
            self.checkOut = checkOut
            self.breakTimes = breakTimes
            self.editable = editable
        }
        
        func addBreakTime() {
            let breakTime = BreakTime(start: checkIn, end: checkIn)
            breakTimes.append(breakTime)
        }
        
        func removeBreakTime() {
            breakTimes.removeAll(where: { $0.id == removeId })
            removeId = nil
        }
        
        func isValid(_ breakTime: BreakTime) -> Bool {
            if breakTime.start > breakTime.end { return false }
            if breakTime.start < checkIn { return false }
            if breakTime.end > checkOut { return false }
            
            let sorted = breakTimes.sorted { $0.start < $1.start }
            for (a, b) in zip(sorted, sorted.dropFirst()) {
                if a.end > b.start {
                    if a.id == breakTime.id || b.id == breakTime.id {
                        return false
                    }
                }
            }
            
            return true
        }
        
        static func == (lhs: TimeRecordEditViewModel.TimeRecord, rhs: TimeRecordEditViewModel.TimeRecord) -> Bool {
            lhs.id == rhs.id &&
            lhs.checkIn == rhs.checkIn &&
            lhs.checkOut == rhs.checkOut &&
            lhs.breakTimes == rhs.breakTimes
        }
    }
    
    @ObservationIgnored private var date: Date
    
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
    
    func isValid() -> Bool {
        if records.contains(where: { !isValid($0) }) { return false }
        
        for rec in records {
            if rec.breakTimes.contains(where: { !rec.isValid($0) }) {
                return false
            }
        }
        
        return true
    }
    
    func isValid(_ record: TimeRecord) -> Bool {
        if record.checkIn > record.checkOut { return false }
        if record.checkIn < date { return false }
        
        let sorted = records.sorted { $0.checkIn < $1.checkIn }
        for (a, b) in zip(sorted, sorted.dropFirst()) {
            if a.checkOut > b.checkIn {
                if a.id == record.id || b.id == record.id {
                    return false
                }
            }
        }
        
        return true
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
        var editable: Bool
        var removeId: SleepRecord.ID? = nil
        
        var uptime: TimeInterval {
            var interval = shutdown.timeIntervalSince(launch)
            for sleep in self.sleepRecords {
                interval -= sleep.end.timeIntervalSince(sleep.start)
            }
            
            return interval
        }
        
        init(id: UUID = UUID(), launch: Date, shutdown: Date, sleepRecords: [SleepRecord] = [], editable: Bool = true) {
            self.id = id
            self.launch = launch
            self.shutdown = shutdown
            self.sleepRecords = sleepRecords
            self.editable = editable
        }
        
        func addSleep() {
            let sleep = SleepRecord(start: launch, end: launch)
            sleepRecords.append(sleep)
        }
        
        func removeSleep() {
            sleepRecords.removeAll(where: { $0.id == removeId })
            removeId = nil
        }
        
        func isValid(_ record: SleepRecord) -> Bool {
            if record.start > record.end { return false }
            if record.start < launch { return false }
            if record.end > shutdown { return false }
            
            let sorted = sleepRecords.sorted { $0.start < $1.start }
            for (a, b) in zip(sorted, sorted.dropFirst()) {
                if a.end > b.start {
                    if a.id == record.id || b.id == record.id {
                        return false
                    }
                }
            }
            
            return true
        }
        
        static func == (lhs: UptimeRecordEditViewModel.SystemUptimeRecord, rhs: UptimeRecordEditViewModel.SystemUptimeRecord) -> Bool {
            lhs.id == rhs.id &&
            lhs.launch == rhs.launch &&
            lhs.shutdown == rhs.shutdown &&
            lhs.sleepRecords == rhs.sleepRecords
        }
    }
    
    @ObservationIgnored private var date: Date
    
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
    
    func isValid() -> Bool {
        if records.contains(where: { !isValid($0) }) { return false }
        
        for rec in records {
            if rec.sleepRecords.contains(where: { !rec.isValid($0) }) {
                return false
            }
        }
        
        return true
    }
    
    func isValid(_ record: SystemUptimeRecord) -> Bool {
        if record.launch > record.shutdown { return false }
        if record.launch < date { return false }
        
        let sorted = records.sorted { $0.launch < $1.launch }
        for (a, b) in zip(sorted, sorted.dropFirst()) {
            if a.shutdown > b.launch {
                if a.id == record.id || b.id == record.id {
                    return false
                }
            }
        }
        
        return true
    }
}

extension TimeRecord {
    func asViewModel() -> TimeRecordEditViewModel.TimeRecord {
        TimeRecordEditViewModel.TimeRecord(
            id: self.id,
            checkIn: self.checkIn ?? .now,
            checkOut: self.checkOut ?? .now,
            breakTimes: self.breakTimes.map { $0.asViewModel() },
            editable: max(self.checkIn ?? .distantFuture, self.checkOut ?? .distantFuture) < .now
        )
    }
}

extension TimeRecord.BreakTime {
    func asViewModel() -> TimeRecordEditViewModel.BreakTime {
        TimeRecordEditViewModel.BreakTime(
            id: self.id,
            start: self.start ?? .now,
            end: self.end ?? .now
        )
    }
}

extension SystemUptimeRecord {
    func asViewModel() -> UptimeRecordEditViewModel.SystemUptimeRecord {
        UptimeRecordEditViewModel.SystemUptimeRecord(
            id: self.id,
            launch: self.launch,
            shutdown: self.shutdown,
            sleepRecords: self.sleepRecords.map { $0.asViewModel() },
            editable: max(self.launch, self.shutdown) < Calendar.current.startOfDay(for: .now)
        )
    }
}

extension SystemUptimeRecord.SleepRecord {
    func asViewModel() -> UptimeRecordEditViewModel.SleepRecord {
        UptimeRecordEditViewModel.SleepRecord(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}

extension TimeRecordEditViewModel.TimeRecord {
    func asRecord() -> TimeRecord {
        TimeRecord(
            id: self.id,
            checkIn: self.checkIn,
            checkOut: self.checkOut,
            breakTimes: self.breakTimes.map { $0.asBreakTime() }
        )
    }
}

extension TimeRecordEditViewModel.BreakTime {
    func asBreakTime() -> TimeRecord.BreakTime {
        TimeRecord.BreakTime(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}

extension UptimeRecordEditViewModel.SystemUptimeRecord {
    func asRecord() -> SystemUptimeRecord {
        SystemUptimeRecord(
            id: self.id,
            launch: self.launch,
            shutdown: self.shutdown,
            sleepRecords: self.sleepRecords.map { $0.asRecord() }
        )
    }
}

extension UptimeRecordEditViewModel.SleepRecord {
    func asRecord() -> SystemUptimeRecord.SleepRecord {
        SystemUptimeRecord.SleepRecord(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}

extension [TimeRecordEditViewModel.TimeRecord] {
    func copy() -> [TimeRecordEditViewModel.TimeRecord] {
        self.map { $0.copy() }
    }
}

extension TimeRecordEditViewModel.TimeRecord {
    func copy() -> TimeRecordEditViewModel.TimeRecord {
        TimeRecordEditViewModel.TimeRecord(
            id: self.id,
            checkIn: self.checkIn,
            checkOut: self.checkOut,
            breakTimes: self.breakTimes.map { $0.copy() }
        )
    }
}

extension TimeRecordEditViewModel.BreakTime {
    func copy() -> TimeRecordEditViewModel.BreakTime {
        TimeRecordEditViewModel.BreakTime(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}

extension [UptimeRecordEditViewModel.SystemUptimeRecord] {
    func copy() -> [UptimeRecordEditViewModel.SystemUptimeRecord] {
        self.map { $0.copy() }
    }
}

extension UptimeRecordEditViewModel.SystemUptimeRecord {
    func copy() -> UptimeRecordEditViewModel.SystemUptimeRecord {
        UptimeRecordEditViewModel.SystemUptimeRecord(
            id: self.id,
            launch: self.launch,
            shutdown: self.shutdown,
            sleepRecords: self.sleepRecords.map { $0.copy() }
        )
    }
}

extension UptimeRecordEditViewModel.SleepRecord {
    func copy() -> UptimeRecordEditViewModel.SleepRecord {
        UptimeRecordEditViewModel.SleepRecord(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}
