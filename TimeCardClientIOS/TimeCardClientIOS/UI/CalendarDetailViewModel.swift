//
//  CalendarDetailViewModel.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2026/03/13.
//

import Foundation

@Observable
class CalendarDetailViewModel {
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
        
        static func == (lhs: CalendarDetailViewModel.BreakTime, rhs: CalendarDetailViewModel.BreakTime) -> Bool {
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
        
        init(id: UUID = UUID(), checkIn: Date, checkOut: Date, breakTimes: [BreakTime] = []) {
            self.id = id
            self.checkIn = checkIn
            self.checkOut = checkOut
            self.breakTimes = breakTimes
        }
        
        func addItem() {
            let breakTime = BreakTime(start: checkIn, end: checkIn)
            breakTimes.append(breakTime)
        }
        
        func deleteItems(indexes: IndexSet) {
            breakTimes.remove(atOffsets: indexes)
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
        
        static func == (lhs: CalendarDetailViewModel.TimeRecord, rhs: CalendarDetailViewModel.TimeRecord) -> Bool {
            lhs.id == rhs.id &&
            lhs.checkIn == rhs.checkIn &&
            lhs.checkOut == rhs.checkOut &&
            lhs.breakTimes == rhs.breakTimes
        }
    }
    
    @ObservationIgnored private let repository: CalendarRecordRepository
    
    var date: Date
    var records: [TimeRecord] = []
    var message: String = ""
    private var recordsOriginal: [TimeRecord] = []
    
    init(_ repository: CalendarRecordRepository, _ date: Date) {
        self.repository = repository
        self.date = date
        
        if let record = try? repository.getRecord(year: date.year, month: date.month, day: date.day) {
            self.records = record.records.map { $0.asViewModel() }
            self.recordsOriginal = self.records.copy()
        }
    }
    
    func updateRecord() {
        Task {
            do {
                let record = CalendarRecord(date: date, records: records.map { $0.asRecord() })
                try await repository.updateRecord(record)
                
                self.recordsOriginal = self.records.copy()
            } catch {
                await MainActor.run {
                    self.message = "更新に失敗しました"
                }
            }
        }
    }
    
    func addItem() {
        let record = TimeRecord(checkIn: date, checkOut: date)
        records.append(record)
    }
    
    func deleteItems(indexes: IndexSet) {
        records.remove(atOffsets: indexes)
    }
    
    func isValid() -> Bool {
        if records.contains(where: { !isValid($0) }) { return false }
        
        for rec in records {
            if rec.breakTimes.contains(where: { !rec.isValid($0) }) {
                return false
            }
        }
        
        return records != recordsOriginal
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

extension TimeRecord {
    func asViewModel() -> CalendarDetailViewModel.TimeRecord {
        CalendarDetailViewModel.TimeRecord(
            id: self.id,
            checkIn: self.checkIn ?? .now,
            checkOut: self.checkOut ?? .now,
            breakTimes: self.breakTimes.map { $0.asViewModel() }
        )
    }
}

extension TimeRecord.BreakTime {
    func asViewModel() -> CalendarDetailViewModel.BreakTime {
        CalendarDetailViewModel.BreakTime(
            id: self.id,
            start: self.start ?? .now,
            end: self.end ?? .now
        )
    }
}

extension CalendarDetailViewModel.TimeRecord {
    func asRecord() -> TimeRecord {
        TimeRecord(
            id: self.id,
            checkIn: self.checkIn,
            checkOut: self.checkOut,
            breakTimes: self.breakTimes.map { $0.asBreakTime() }
        )
    }
}

extension CalendarDetailViewModel.BreakTime {
    func asBreakTime() -> TimeRecord.BreakTime {
        TimeRecord.BreakTime(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}

extension [CalendarDetailViewModel.TimeRecord] {
    func copy() -> [CalendarDetailViewModel.TimeRecord] {
        self.map { $0.copy() }
    }
}

extension CalendarDetailViewModel.TimeRecord {
    func copy() -> CalendarDetailViewModel.TimeRecord {
        CalendarDetailViewModel.TimeRecord(
            id: self.id,
            checkIn: self.checkIn,
            checkOut: self.checkOut,
            breakTimes: self.breakTimes.map { $0.copy() }
        )
    }
}

extension CalendarDetailViewModel.BreakTime {
    func copy() -> CalendarDetailViewModel.BreakTime {
        CalendarDetailViewModel.BreakTime(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}
