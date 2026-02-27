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
