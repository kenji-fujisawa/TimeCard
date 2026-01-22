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
    func insertRecord(record: TimeRecord) throws
    func updateRecord(record: TimeRecord) throws
    func deleteRecord(record: TimeRecord) throws
    func deleteRecords(year: Int, month: Int) throws
}

class DefaultLocalDataSource: LocalDataSource {
    private let context: ModelContext
    
    init(context: ModelContext) {
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
    
    func insertRecord(record: TimeRecord) throws {
        context.insert(record.asLocal())
        try context.save()
    }
    
    func updateRecord(record: TimeRecord) throws {
        guard let local = try getRecord(id: record.id) else { return }
        local.year = record.year
        local.month = record.month
        local.checkIn = record.checkIn
        local.checkOut = record.checkOut
        local.breakTimes = record.breakTimes.map { $0.asLocal() }
        try context.save()
    }
    
    func deleteRecord(record: TimeRecord) throws {
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

@Model
class LocalTimeRecord {
    @Model
    class LocalBreakTime {
        var id: UUID
        var start: Date?
        var end: Date?
        var parent: LocalTimeRecord?
        
        init(id: UUID, start: Date? = nil, end: Date? = nil, parent: LocalTimeRecord? = nil) {
            self.id = id
            self.start = start
            self.end = end
            self.parent = parent
        }
        
        func asBreakTime() -> TimeRecord.BreakTime {
            TimeRecord.BreakTime(
                id: self.id,
                start: self.start,
                end: self.end
            )
        }
    }
    
    #Index<LocalTimeRecord>([\.id], [\.year, \.month])
    
    var id: UUID
    var year: Int
    var month: Int
    var checkIn: Date?
    var checkOut: Date?
    
    @Relationship(deleteRule: .cascade, inverse: \LocalBreakTime.parent)
    var breakTimes: [LocalBreakTime]
    
    init(id: UUID, year: Int, month: Int, checkIn: Date? = nil, checkOut: Date? = nil, breakTimes: [LocalBreakTime]) {
        self.id = id
        self.year = year
        self.month = month
        self.checkIn = checkIn
        self.checkOut = checkOut
        self.breakTimes = breakTimes
    }
    
    func asTimeRecord() -> TimeRecord {
        TimeRecord(
            id: self.id,
            year: self.year,
            month: self.month,
            checkIn: self.checkIn,
            checkOut: self.checkOut,
            breakTimes: self.breakTimes
                .sorted(by: { $0.start ?? .distantPast < $1.start ?? .distantPast })
                .map { $0.asBreakTime() }
        )
    }
}

extension TimeRecord {
    func asLocal() -> LocalTimeRecord {
        LocalTimeRecord(
            id: self.id,
            year: self.year,
            month: self.month,
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
