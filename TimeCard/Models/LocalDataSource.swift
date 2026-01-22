//
//  LocalDataSource.swift
//  TimeCard
//
//  Created by uhimania on 2026/01/13.
//

import Foundation
import SwiftData

protocol LocalDataSource {
    func getTimeRecords(year: Int, month: Int) throws -> [TimeRecord]
    func insertTimeRecord(record: TimeRecord) throws
    func updateTimeRecord(record: TimeRecord) throws
    func deleteTimeRecord(record: TimeRecord) throws
    
    func getUptimeRecords(year: Int, month: Int) throws -> [SystemUptimeRecord]
    func insertUptimeRecord(record: SystemUptimeRecord) throws
    func updateUptimeRecord(record: SystemUptimeRecord) throws
    func deleteUptimeRecord(record: SystemUptimeRecord) throws
}

class DefaultLocalDataSource: LocalDataSource {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func getTimeRecords(year: Int, month: Int) throws -> [TimeRecord] {
        let descriptor = FetchDescriptor<TimeRecord>(
            predicate: #Predicate { $0.year == year && $0.month == month },
            sortBy: [.init(\.checkIn)]
        )
        return try context.fetch(descriptor)
    }
    
    private func getTimeRecord(id: UUID) throws -> TimeRecord? {
        let descriptor = FetchDescriptor<TimeRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
    
    func insertTimeRecord(record: TimeRecord) throws {
        context.insert(record)
        try context.save()
    }
    
    func updateTimeRecord(record: TimeRecord) throws {
        if let rec = try getTimeRecord(id: record.id) {
            // records 側のオブジェクトが削除されてしまうのでコピーを渡す
            let breakTimes = record.breakTimes.map { $0.copy() }
            // "Illegal attempt to map a relationship containing temporary objects to its identifiers." エラーになるため事前に insert しておく
            breakTimes.forEach { context.insert($0) }
            try context.save()
            
            rec.year = record.year
            rec.month = record.month
            rec.checkIn = record.checkIn
            rec.checkOut = record.checkOut
            rec.breakTimes = breakTimes
            try context.save()
        }
    }
    
    func deleteTimeRecord(record: TimeRecord) throws {
        if let rec = try getTimeRecord(id: record.id) {
            context.delete(rec)
            try context.save()
        }
    }
    
    func getUptimeRecords(year: Int, month: Int) throws -> [SystemUptimeRecord] {
        let descriptor = FetchDescriptor<SystemUptimeRecord>(
            predicate: #Predicate { $0.year == year && $0.month == month },
            sortBy: [.init(\.launch)]
        )
        return try context.fetch(descriptor)
    }
    
    private func getUptimeRecord(id: UUID) throws -> SystemUptimeRecord? {
        let descriptor = FetchDescriptor<SystemUptimeRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
    
    func insertUptimeRecord(record: SystemUptimeRecord) throws {
        context.insert(record)
        try context.save()
    }
    
    func updateUptimeRecord(record: SystemUptimeRecord) throws {
        if let rec = try getUptimeRecord(id: record.id) {
            // records 側のオブジェクトが削除されてしまうのでコピーを渡す
            let sleepRecords = record.sleepRecords.map { $0.copy() }
            // "Illegal attempt to map a relationship containing temporary objects to its identifiers." エラーになるため事前に insert しておく
            sleepRecords.forEach { context.insert($0) }
            try context.save()
            
            rec.year = record.year
            rec.month = record.month
            rec.day = record.day
            rec.launch = record.launch
            rec.shutdown = record.shutdown
            rec.sleepRecords = sleepRecords
            try context.save()
        }
    }
    
    func deleteUptimeRecord(record: SystemUptimeRecord) throws {
        if let rec = try getUptimeRecord(id: record.id) {
            context.delete(rec)
            try context.save()
        }
    }
}

extension TimeRecord {
    func copy() -> TimeRecord {
        TimeRecord(
            id: self.id,
            year: self.year,
            month: self.month,
            checkIn: self.checkIn,
            checkOut: self.checkOut,
            breakTimes: self.breakTimes.map { $0.copy() }
        )
    }
}

extension TimeRecord.BreakTime {
    func copy() -> TimeRecord.BreakTime {
        TimeRecord.BreakTime(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}

extension SystemUptimeRecord {
    func copy() -> SystemUptimeRecord {
        SystemUptimeRecord(
            id: self.id,
            year: self.year,
            month: self.month,
            day: self.day,
            launch: self.launch,
            shutdown: self.shutdown,
            sleepRecords: self.sleepRecords.map { $0.copy() }
        )
    }
}

extension SystemUptimeRecord.SleepRecord {
    func copy() -> SystemUptimeRecord.SleepRecord {
        SystemUptimeRecord.SleepRecord(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}
