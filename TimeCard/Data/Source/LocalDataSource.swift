//
//  LocalDataSource.swift
//  TimeCard
//
//  Created by uhimania on 2026/01/13.
//

import Foundation
import SwiftData

protocol LocalDataSource {
    func getTimeRecord(id: UUID) throws -> TimeRecord?
    func getBreakTime(id: UUID) throws -> TimeRecord.BreakTime?
    
    func getTimeRecords(year: Int, month: Int) throws -> [TimeRecord]
    func insertTimeRecord(_ record: TimeRecord) throws
    func updateTimeRecord(_ record: TimeRecord) throws
    func deleteTimeRecord(_ record: TimeRecord) throws
    
    func getUptimeRecords(year: Int, month: Int) throws -> [SystemUptimeRecord]
    func insertUptimeRecord(_ record: SystemUptimeRecord) throws
    func updateUptimeRecord(_ record: SystemUptimeRecord) throws
    func deleteUptimeRecord(_ record: SystemUptimeRecord) throws
}

class DefaultLocalDataSource: LocalDataSource {
    private let context: ModelContext
    
    init(_ context: ModelContext) {
        self.context = context
    }
    
    func getTimeRecord(id: UUID) throws -> TimeRecord? {
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first?.toTimeRecord()
    }
    
    func getBreakTime(id: UUID) throws -> TimeRecord.BreakTime? {
        let descriptor = FetchDescriptor<LocalTimeRecord.BreakTime>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first?.toBreakTime()
    }
    
    func getTimeRecords(year: Int, month: Int) throws -> [TimeRecord] {
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.year == year && $0.month == month },
            sortBy: [.init(\.checkIn)]
        )
        return try context.fetch(descriptor).map { $0.toTimeRecord() }
    }
    
    private func getLocalTimeRecord(id: UUID) throws -> LocalTimeRecord? {
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
    
    func insertTimeRecord(_ record: TimeRecord) throws {
        context.insert(record.toLocal())
        try context.save()
    }
    
    func updateTimeRecord(_ record: TimeRecord) throws {
        if let rec = try getLocalTimeRecord(id: record.id) {
            rec.year = record.year
            rec.month = record.month
            rec.checkIn = record.checkIn
            rec.checkOut = record.checkOut
            rec.breakTimes = record.breakTimes.map { $0.toLocal() }
            try context.save()
        }
    }
    
    func deleteTimeRecord(_ record: TimeRecord) throws {
        if let rec = try getLocalTimeRecord(id: record.id) {
            context.delete(rec)
            try context.save()
        }
    }
    
    func getUptimeRecords(year: Int, month: Int) throws -> [SystemUptimeRecord] {
        let descriptor = FetchDescriptor<LocalUptimeRecord>(
            predicate: #Predicate { $0.year == year && $0.month == month },
            sortBy: [.init(\.launch)]
        )
        return try context.fetch(descriptor).map { $0.toUptimeRecord() }
    }
    
    private func getLocalUptimeRecord(id: UUID) throws -> LocalUptimeRecord? {
        let descriptor = FetchDescriptor<LocalUptimeRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
    
    func insertUptimeRecord(_ record: SystemUptimeRecord) throws {
        context.insert(record.toLocal())
        try context.save()
    }
    
    func updateUptimeRecord(_ record: SystemUptimeRecord) throws {
        if let rec = try getLocalUptimeRecord(id: record.id) {
            rec.year = record.year
            rec.month = record.month
            rec.day = record.day
            rec.launch = record.launch
            rec.shutdown = record.shutdown
            rec.sleepRecords = record.sleepRecords.map { $0.toLocal() }
            try context.save()
        }
    }
    
    func deleteUptimeRecord(_ record: SystemUptimeRecord) throws {
        if let rec = try getLocalUptimeRecord(id: record.id) {
            context.delete(rec)
            try context.save()
        }
    }
}

extension TimeRecord {
    func toLocal() -> LocalTimeRecord {
        LocalTimeRecord(
            id: self.id,
            year: self.year,
            month: self.month,
            checkIn: self.checkIn,
            checkOut: self.checkOut,
            breakTimes: self.breakTimes.map { $0.toLocal() }
        )
    }
}

extension TimeRecord.BreakTime {
    func toLocal() -> LocalTimeRecord.BreakTime {
        LocalTimeRecord.BreakTime(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}

extension SystemUptimeRecord {
    func toLocal() -> LocalUptimeRecord {
        LocalUptimeRecord(
            id: self.id,
            year: self.year,
            month: self.month,
            day: self.day,
            launch: self.launch,
            shutdown: self.shutdown,
            sleepRecords: self.sleepRecords.map { $0.toLocal() }
        )
    }
}

extension SystemUptimeRecord.SleepRecord {
    func toLocal() -> LocalUptimeRecord.SleepRecord {
        LocalUptimeRecord.SleepRecord(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}

extension LocalTimeRecord {
    func toTimeRecord() -> TimeRecord {
        TimeRecord(
            id: self.id,
            year: self.year,
            month: self.month,
            checkIn: self.checkIn,
            checkOut: self.checkOut,
            breakTimes: self.breakTimes
                .sorted { $0.start ?? .distantPast < $1.start ?? .distantPast }
                .map { $0.toBreakTime() }
        )
    }
}

extension LocalTimeRecord.BreakTime {
    func toBreakTime() -> TimeRecord.BreakTime {
        TimeRecord.BreakTime(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}

extension LocalUptimeRecord {
    func toUptimeRecord() -> SystemUptimeRecord {
        SystemUptimeRecord(
            id: self.id,
            year: self.year,
            month: self.month,
            day: self.day,
            launch: self.launch,
            shutdown: self.shutdown,
            sleepRecords: self.sleepRecords
                .sorted { $0.start < $1.start }
                .map { $0.toSleepRecord() }
        )
    }
}

extension LocalUptimeRecord.SleepRecord {
    func toSleepRecord() -> SystemUptimeRecord.SleepRecord {
        SystemUptimeRecord.SleepRecord(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}
