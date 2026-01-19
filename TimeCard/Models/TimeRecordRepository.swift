//
//  TimeRecordRepository.swift
//  TimeCard
//
//  Created by uhimania on 2026/01/14.
//

import Foundation

enum WorkState {
    case OffWork
    case AtWork
    case AtBreak
}

protocol TimeRecordRepository {
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
    
    private func getRecords(year: Int, month: Int) throws -> [TimeRecord] {
        try source.getTimeRecords(year: year, month: month)
    }
    
    func getState() -> WorkState {
        let now = Date.now
        let records = try? getRecords(year: now.year, month: now.month)
        guard let record = records?.last else {
            return .OffWork
        }
        
        if record.checkIn == nil {
            return .OffWork
        }
        
        let latest = record.sortedBreakTimes.last
        if (latest?.start != nil && latest?.end == nil) {
            return .AtBreak
        }
        
        if record.checkOut == nil {
            return .AtWork
        }
        
        return .OffWork
    }
    
    func checkIn() throws {
        guard getState() == .OffWork else {
            throw TimeRecordError.stateMismatch
        }
        
        let now = Date.now
        let record = TimeRecord(
            year: now.year,
            month: now.month,
            checkIn: now
        )
        try source.insertTimeRecord(record: record)
    }
    
    func checkOut() throws {
        guard getState() == .AtWork else {
            throw TimeRecordError.stateMismatch
        }
        
        let now = Date.now
        if let record = try getRecords(year: now.year, month: now.month).last {
            record.checkOut = now
            try source.updateTimeRecord(record: record)
        }
    }
    
    func startBreak() throws {
        guard getState() == .AtWork else {
            throw TimeRecordError.stateMismatch
        }
        
        let now = Date.now
        if let record = try getRecords(year: now.year, month: now.month).last {
            record.breakTimes.append(TimeRecord.BreakTime(start: now))
            try source.updateTimeRecord(record: record)
        }
    }
    
    func endBreak() throws {
        guard getState() == .AtBreak else {
            throw TimeRecordError.stateMismatch
        }
        
        let now = Date.now
        if let record = try getRecords(year: now.year, month: now.month).last,
           let breakTime = record.sortedBreakTimes.last {
            breakTime.end = now
            try source.updateTimeRecord(record: record)
        }
    }
}
