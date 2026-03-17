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
        return try context.fetch(descriptor).first?.asTimeRecord()
    }
    
    func getBreakTime(id: UUID) throws -> TimeRecord.BreakTime? {
        let descriptor = FetchDescriptor<LocalTimeRecord.BreakTime>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first?.asBreakTime()
    }
    
    func getTimeRecords(year: Int, month: Int) throws -> [TimeRecord] {
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.year == year && $0.month == month },
            sortBy: [.init(\.checkIn)]
        )
        return try context.fetch(descriptor).map { $0.asTimeRecord() }
    }
    
    private func getLocalTimeRecord(id: UUID) throws -> LocalTimeRecord? {
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
    
    func insertTimeRecord(_ record: TimeRecord) throws {
        context.insert(record.asLocal())
        try context.save()
    }
    
    func updateTimeRecord(_ record: TimeRecord) throws {
        if let rec = try getLocalTimeRecord(id: record.id) {
            if let checkIn = record.checkIn {
                rec.year = checkIn.year
                rec.month = checkIn.month
            }
            rec.checkIn = record.checkIn
            rec.checkOut = record.checkOut
            rec.breakTimes = record.breakTimes.map { $0.asLocal() }
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
        return try context.fetch(descriptor).map { $0.asUptimeRecord() }
    }
    
    private func getLocalUptimeRecord(id: UUID) throws -> LocalUptimeRecord? {
        let descriptor = FetchDescriptor<LocalUptimeRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
    
    func insertUptimeRecord(_ record: SystemUptimeRecord) throws {
        context.insert(record.asLocal())
        try context.save()
    }
    
    func updateUptimeRecord(_ record: SystemUptimeRecord) throws {
        if let rec = try getLocalUptimeRecord(id: record.id) {
            rec.year = record.launch.year
            rec.month = record.launch.month
            rec.day = record.launch.day
            rec.launch = record.launch
            rec.shutdown = record.shutdown
            rec.sleepRecords = record.sleepRecords.map { $0.asLocal() }
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
    func asLocal() -> LocalTimeRecord {
        LocalTimeRecord(
            id: self.id,
            year: self.checkIn?.year ?? Date.now.year,
            month: self.checkIn?.month ?? Date.now.month,
            checkIn: self.checkIn,
            checkOut: self.checkOut,
            breakTimes: self.breakTimes.map { $0.asLocal() }
        )
    }
}

extension TimeRecord.BreakTime {
    func asLocal() -> LocalTimeRecord.BreakTime {
        LocalTimeRecord.BreakTime(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}

extension SystemUptimeRecord {
    func asLocal() -> LocalUptimeRecord {
        LocalUptimeRecord(
            id: self.id,
            year: self.launch.year,
            month: self.launch.month,
            day: self.launch.day,
            launch: self.launch,
            shutdown: self.shutdown,
            sleepRecords: self.sleepRecords.map { $0.asLocal() }
        )
    }
}

extension SystemUptimeRecord.SleepRecord {
    func asLocal() -> LocalUptimeRecord.SleepRecord {
        LocalUptimeRecord.SleepRecord(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}

extension LocalTimeRecord {
    func asTimeRecord() -> TimeRecord {
        TimeRecord(
            id: self.id,
            checkIn: self.checkIn,
            checkOut: self.checkOut,
            breakTimes: self.breakTimes
                .sorted { $0.start ?? .distantPast < $1.start ?? .distantPast }
                .map { $0.asBreakTime() }
        )
    }
}

extension LocalTimeRecord.BreakTime {
    func asBreakTime() -> TimeRecord.BreakTime {
        TimeRecord.BreakTime(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}

extension LocalUptimeRecord {
    func asUptimeRecord() -> SystemUptimeRecord {
        SystemUptimeRecord(
            id: self.id,
            launch: self.launch,
            shutdown: self.shutdown,
            sleepRecords: self.sleepRecords
                .sorted { $0.start < $1.start }
                .map { $0.asSleepRecord() }
        )
    }
}

extension LocalUptimeRecord.SleepRecord {
    func asSleepRecord() -> SystemUptimeRecord.SleepRecord {
        SystemUptimeRecord.SleepRecord(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}
