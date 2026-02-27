//
//  TimeRecordRepository.swift
//  TimeCard
//
//  Created by uhimania on 2026/01/14.
//

import Foundation

enum WorkState {
    case offWork
    case atWork
    case atBreak
}

protocol TimeRecordRepository {
    func getRecords(year: Int, month: Int) throws -> [TimeRecord]
    func getRecord(id: UUID) throws -> TimeRecord?
    func getBreakTime(id: UUID) throws -> TimeRecord.BreakTime?
    
    func insert(_ record: TimeRecord) throws
    func update(_ record: TimeRecord) throws
    func delete(_ record: TimeRecord) throws
    
    func getState() -> WorkState
    func checkIn() throws
    func checkOut() throws
    func startBreak() throws
    func endBreak() throws
}

class DefaultTimeRecordRepository: TimeRecordRepository {
    enum TimeRecordError: Error {
        case stateMismatch
    }
    
    private let source: LocalDataSource
    
    init(source: LocalDataSource) {
        self.source = source
    }
    
    func getRecords(year: Int, month: Int) throws -> [TimeRecord] {
        try source.getTimeRecords(year: year, month: month)
    }
    
    func getRecord(id: UUID) throws -> TimeRecord? {
        try source.getTimeRecord(id: id)
    }
    
    func getBreakTime(id: UUID) throws -> TimeRecord.BreakTime? {
        try source.getBreakTime(id: id)
    }
    
    func insert(_ record: TimeRecord) throws {
        try source.insertTimeRecord(record)
    }
    
    func update(_ record: TimeRecord) throws {
        try source.updateTimeRecord(record)
    }
    
    func delete(_ record: TimeRecord) throws {
        try source.deleteTimeRecord(record)
    }
    
    func getState() -> WorkState {
        let now = Date.now
        let records = try? getRecords(year: now.year, month: now.month)
        guard let record = records?.last else {
            return .offWork
        }
        
        if record.checkIn == nil {
            return .offWork
        }
        
        let latest = record.breakTimes.last
        if (latest?.start != nil && latest?.end == nil) {
            return .atBreak
        }
        
        if record.checkOut == nil {
            return .atWork
        }
        
        return .offWork
    }
    
    func checkIn() throws {
        guard getState() == .offWork else {
            throw TimeRecordError.stateMismatch
        }
        
        let now = Date.now
        let record = TimeRecord(
            year: now.year,
            month: now.month,
            checkIn: now
        )
        try source.insertTimeRecord(record)
    }
    
    func checkOut() throws {
        guard getState() == .atWork else {
            throw TimeRecordError.stateMismatch
        }
        
        let now = Date.now
        if var record = try getRecords(year: now.year, month: now.month).last {
            record.checkOut = now
            try source.updateTimeRecord(record)
        }
    }
    
    func startBreak() throws {
        guard getState() == .atWork else {
            throw TimeRecordError.stateMismatch
        }
        
        let now = Date.now
        if var record = try getRecords(year: now.year, month: now.month).last {
            record.breakTimes.append(TimeRecord.BreakTime(start: now))
            try source.updateTimeRecord(record)
        }
    }
    
    func endBreak() throws {
        guard getState() == .atBreak else {
            throw TimeRecordError.stateMismatch
        }
        
        let now = Date.now
        if var record = try getRecords(year: now.year, month: now.month).last,
           !record.breakTimes.isEmpty {
            let index = record.breakTimes.count - 1
            record.breakTimes[index].end = now
            try source.updateTimeRecord(record)
        }
    }
}
