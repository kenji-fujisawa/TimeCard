//
//  CalendarRecordRepository.swift
//  TimeCard
//
//  Created by uhimania on 2026/01/13.
//

import Foundation
import SwiftData

protocol CalendarRecordRepository {
    func getRecordsStream(year: Int, month: Int) -> AsyncThrowingStream<[CalendarRecord], any Error>
    func getRecord(year: Int, month: Int, day: Int) throws -> CalendarRecord
    func updateRecord(_ record: CalendarRecord) throws
}

class DefaultCalendarRecordRepository: CalendarRecordRepository {
    private let source: LocalDataSource
    
    init(_ source: LocalDataSource) {
        self.source = source
    }
    
    func getRecordsStream(year: Int, month: Int) -> AsyncThrowingStream<[CalendarRecord], any Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    continuation.yield(try getRecords(year: year, month: month))
                } catch {
                    continuation.finish(throwing: error)
                    return
                }
                
                let notifications = NotificationCenter.default.notifications(named: ModelContext.didSave)
                for await _ in notifications {
                    do {
                        continuation.yield(try getRecords(year: year, month: month))
                    } catch {
                        continuation.finish(throwing: error)
                        break
                    }
                }
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    private func getRecords(year: Int, month: Int) throws -> [CalendarRecord] {
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
        
        var records: [CalendarRecord] = []
        Calendar.current.datesOf(year: year, month: month).forEach { date in
            records.append(CalendarRecord(
                date: date,
                timeRecords: timeRecords[date.day] ?? [],
                uptimeRecords: uptimes[date.day] ?? []
            ))
        }
        
        return records
    }
    
    func getRecord(year: Int, month: Int, day: Int) throws -> CalendarRecord {
        let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
        let timeRecords = try source.getTimeRecords(year: year, month: month).filter { $0.checkIn?.day == day }
        let uptimeRecords = try source.getUptimeRecords(year: year, month: month).filter { $0.launch.day == day }
        return CalendarRecord(date: date, timeRecords: timeRecords, uptimeRecords: uptimeRecords)
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
