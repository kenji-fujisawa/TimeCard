//
//  LocalDataSource.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2026/01/07.
//

import Foundation
import SwiftData

protocol LocalDataSource {
    func getRecords(year: Int, month: Int) throws -> [TimeRecord]
    func insertRecord(_ record: TimeRecord) throws
    func updateRecord(_ record: TimeRecord) throws
    func deleteRecord(_ record: TimeRecord) throws
    func deleteRecords(year: Int, month: Int) throws
}

class DefaultLocalDataSource: LocalDataSource {
    private let context: ModelContext
    
    init(_ context: ModelContext) {
        self.context = context
    }
    
    func getRecords(year: Int, month: Int) throws -> [TimeRecord] {
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.year == year && $0.month == month },
            sortBy: [.init(\.checkIn)]
        )
        let records = try context.fetch(descriptor)
        return records.map { $0.asTimeRecord() }
    }
    
    private func getRecord(id: UUID) throws -> LocalTimeRecord? {
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
    
    func insertRecord(_ record: TimeRecord) throws {
        context.insert(record.asLocal())
        try context.save()
    }
    
    func updateRecord(_ record: TimeRecord) throws {
        guard let local = try getRecord(id: record.id) else { return }
        if let checkIn = record.checkIn {
            local.year = checkIn.year
            local.month = checkIn.month
        }
        local.checkIn = record.checkIn
        local.checkOut = record.checkOut
        local.breakTimes = record.breakTimes.map { $0.asLocal() }
        try context.save()
    }
    
    func deleteRecord(_ record: TimeRecord) throws {
        guard let local = try getRecord(id: record.id) else { return }
        context.delete(local)
        try context.save()
    }
    
    func deleteRecords(year: Int, month: Int) throws {
        let descriptor = FetchDescriptor<LocalTimeRecord>(
            predicate: #Predicate { $0.year == year && $0.month == month }
        )
        let records = try context.fetch(descriptor)
        records.forEach { context.delete($0) }
        try context.save()
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
    func asLocal() -> LocalTimeRecord.LocalBreakTime {
        LocalTimeRecord.LocalBreakTime(
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
                .sorted(by: { $0.start ?? .distantPast < $1.start ?? .distantPast })
                .map { $0.asBreakTime() }
        )
    }
}

extension LocalTimeRecord.LocalBreakTime {
    func asBreakTime() -> TimeRecord.BreakTime {
        TimeRecord.BreakTime(
            id: self.id,
            start: self.start,
            end: self.end
        )
    }
}
