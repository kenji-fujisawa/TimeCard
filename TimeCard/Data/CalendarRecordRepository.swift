//
//  CalendarRecordRepository.swift
//  TimeCard
//
//  Created by uhimania on 2026/01/13.
//

import Foundation
import SwiftData

protocol CalendarRecordRepository {
    func getRecordsStream(year: Int, month: Int) -> AsyncStream<[CalendarRecord]>
    func updateRecord(_ record: CalendarRecord) throws
}

class DefaultCalendarRecordRepository: CalendarRecordRepository {
    private let source: LocalDataSource
    private var publish: (([CalendarRecord]) -> Void)? = nil
    private var fetchTask: Task<Void, Never>? = nil
    
    init(_ source: LocalDataSource) {
        self.source = source
    }
    
    deinit {
        fetchTask?.cancel()
    }
    
    func getRecordsStream(year: Int, month: Int) -> AsyncStream<[CalendarRecord]> {
        fetchTask?.cancel()
        fetchTask = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(named: ModelContext.didSave)
            for await _ in notifications {
                await MainActor.run { [weak self] in
                    try? self?.publishRecords(year: year, month: month)
                }
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
            let day = uptime.launch.day
            if uptimes[day] == nil {
                uptimes[day] = []
            }
            uptimes[day]?.append(uptime)
        }
        
        var results: [CalendarRecord] = []
        Calendar.current.datesOf(year: year, month: month).forEach { date in
            results.append(CalendarRecord(
                date: date,
                timeRecords: timeRecords[date.day] ?? [],
                uptimeRecords: uptimes[date.day] ?? []
            ))
        }
        
        publish?(results)
    }
    
    func updateRecord(_ record: CalendarRecord) throws {
        let year = record.date.year
        let month = record.date.month
        let day = record.date.day
        let orgTimes = try source.getTimeRecords(year: year, month: month).filter { $0.checkIn?.day ?? 0 == day }
        let orgUptimes = try source.getUptimeRecords(year: year, month: month).filter { $0.launch.day == day }
        
        let timeInserted = record.timeRecords.filter { rec in
            !orgTimes.contains { $0.id == rec.id }
        }
        let timeUpdated = record.timeRecords.filter { rec in
            let before = orgTimes.first { $0.id == rec.id }
            return before != nil && before != rec
        }
        let timeDeleted = orgTimes.filter { rec in
            !record.timeRecords.contains { $0.id == rec.id }
        }
        
        try timeInserted.forEach { try self.source.insertTimeRecord($0) }
        try timeUpdated.forEach { try self.source.updateTimeRecord($0) }
        try timeDeleted.forEach { try self.source.deleteTimeRecord($0) }
        
        let uptimeInserted = record.uptimeRecords.filter { rec in
            !orgUptimes.contains { $0.id == rec.id }
        }
        let uptimeUpdated = record.uptimeRecords.filter { rec in
            let before = orgUptimes.first { $0.id == rec.id }
            return before != nil && before != rec
        }
        let uptimeDeleted = orgUptimes.filter { rec in
            !record.uptimeRecords.contains { $0.id == rec.id }
        }
        
        try uptimeInserted.forEach { try self.source.insertUptimeRecord($0) }
        try uptimeUpdated.forEach { try self.source.updateUptimeRecord($0) }
        try uptimeDeleted.forEach { try self.source.deleteUptimeRecord($0) }
    }
}
