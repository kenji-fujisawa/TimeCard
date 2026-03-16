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
    class BreakTime: Identifiable {
        var id: UUID
        var start: Date
        var end: Date
        
        init(id: UUID = UUID(), start: Date, end: Date) {
            self.id = id
            self.start = start
            self.end = end
        }
    }
    
    @Observable
    class TimeRecord: Identifiable {
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
    }
    
    @ObservationIgnored private let repository: CalendarRecordRepository
    
    var date: Date
    var records: [TimeRecord] = []
    var message: String = ""
    
    init(_ repository: CalendarRecordRepository, _ date: Date) {
        self.repository = repository
        self.date = date
        
        if let record = try? repository.getRecord(year: date.year, month: date.month, day: date.day) {
            self.records = record.records.map { $0.asViewModel() }
        }
    }
    
    func updateRecord() {
        Task {
            do {
                let record = CalendarRecord(date: date, records: records.map { $0.asRecord() })
                try await repository.updateRecord(record)
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
