//
//  CalendarRecordRepository.swift
//  TimeCard
//
//  Created by uhimania on 2026/01/13.
//

import Foundation
import SwiftData

protocol CalendarRecordRepository {
    func getRecords(year: Int, month: Int) -> AsyncStream<[CalendarRecord]>
    func updateRecord(source: [CalendarRecord], record: CalendarRecord) throws
}

class DefaultCalendarRecordRepository: CalendarRecordRepository {
    private let source: LocalDataSource
    private var publish: (([CalendarRecord]) -> Void)? = nil
    private var fetchTask: Task<Void, Never>? = nil
    
    init(source: LocalDataSource) {
        self.source = source
    }
    
    deinit {
        fetchTask?.cancel()
    }
    
    func getRecords(year: Int, month: Int) -> AsyncStream<[CalendarRecord]> {
        fetchTask?.cancel()
        fetchTask = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(named: ModelContext.didSave)
            for await _ in notifications {
                try? self?.publishRecords(year: year, month: month)
            }
        }
        
        return AsyncStream { continuation in
            publish = { records in
                continuation.yield(records)
            }
            
            try? publishRecords(year: year, month: month)
        }
    }
    
    private func publishRecords(year: Int, month: Int) throws {
        var timeRecords: [Int: [TimeRecord]] = [:]
        try source.getTimeRecords(year: year, month: month).forEach { rec in
            if let day = rec.checkIn?.day {
                if timeRecords[day] == nil {
                    timeRecords[day] = []
                }
                timeRecords[day]?.append(rec)
            }
        }
        
        var uptimes: [Int: [SystemUptimeRecord]] = [:]
        try source.getUptimeRecords(year: year, month: month).forEach { uptime in
            let day = uptime.day
            if uptimes[day] == nil {
                uptimes[day] = []
            }
            uptimes[day]?.append(uptime)
        }
        
        var results: [CalendarRecord] = []
        Calendar.current.datesOf(year: year, month: month).forEach { date in
            results.append(CalendarRecord(
                date: date,
                records: timeRecords[date.day] ?? [],
                systemUptimeRecords: uptimes[date.day] ?? []
            ))
        }
        
        publish?(results)
    }
    
    func updateRecord(source: [CalendarRecord], record: CalendarRecord) throws {
        guard let original = source.first(where: { $0.date == record.date }) else { return }
        
        let timeInserted = record.records.filter { rec in
            !original.records.contains { $0.id == rec.id }
        }
        let timeUpdated = record.records.filter { rec in
            let before = original.records.first { $0.id == rec.id }
            return before != nil && before != rec
        }
        let timeDeleted = original.records.filter { rec in
            !record.records.contains { $0.id == rec.id }
        }
        
        try timeInserted.forEach { try self.source.insertTimeRecord(record: $0) }
        try timeUpdated.forEach { try self.source.updateTimeRecord(record: $0) }
        try timeDeleted.forEach { try self.source.deleteTimeRecord(record: $0) }
        
        let uptimeInserted = record.systemUptimeRecords.filter { rec in
            !original.systemUptimeRecords.contains { $0.id == rec.id }
        }
        let uptimeUpdated = record.systemUptimeRecords.filter { rec in
            let before = original.systemUptimeRecords.first { $0.id == rec.id }
            return before != nil && before != rec
        }
        let uptimeDeleted = original.systemUptimeRecords.filter { rec in
            !record.systemUptimeRecords.contains { $0.id == rec.id }
        }
        
        try uptimeInserted.forEach { try self.source.insertUptimeRecord(record: $0) }
        try uptimeUpdated.forEach { try self.source.updateUptimeRecord(record: $0) }
        try uptimeDeleted.forEach { try self.source.deleteUptimeRecord(record: $0) }
    }
}
