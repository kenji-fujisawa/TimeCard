//
//  SystemUptimeRecordRepository.swift
//  TimeCard
//
//  Created by uhimania on 2026/01/17.
//

import Foundation

protocol SystemUptimeRecordRepository {
    func launch() throws
    func shutdown() throws
    func sleep() throws
    func wake() throws
    func update() throws
    func restoreBackup() throws
}

class DefaultSystemUptimeRecordRepository: SystemUptimeRecordRepository {
    enum SystemUptimeRecordError: Error {
        case notRecording
        case alreadyRecording
        case notSleeping
        case alreadySleeping
    }
    
    private enum State {
        case shutdown
        case running
        case sleep
    }
    
    private let localSource: LocalDataSource
    private let fileSource: FileDataSource
    private var state: State = .shutdown
    
    init(_ localSource: LocalDataSource, _ fileSource: FileDataSource) {
        self.localSource = localSource
        self.fileSource = fileSource
    }
    
    private func getRecord() throws -> SystemUptimeRecord? {
        let now = Date.now
        return try localSource.getUptimeRecords(year: now.year, month: now.month).last
    }
    
    func launch() throws {
        guard state == .shutdown else {
            throw SystemUptimeRecordError.alreadyRecording
        }
        
        let now = Date.now
        let record = SystemUptimeRecord(launch: now, shutdown: now)
        try localSource.insertUptimeRecord(record)
        
        state = .running
    }
    
    func shutdown() throws {
        guard state == .running || state == .sleep else {
            throw SystemUptimeRecordError.notRecording
        }
        guard var record = try getRecord() else {
            throw SystemUptimeRecordError.notRecording
        }
        
        record.shutdown = .now
        
        if state == .sleep {
            let index = record.sleepRecords.count - 1
            record.sleepRecords[index].end = .now
        }
        
        try localSource.updateUptimeRecord(record)
        try saveBackup(record)
        
        state = .shutdown
    }
    
    func sleep() throws {
        guard state == .running else {
            throw SystemUptimeRecordError.alreadySleeping
        }
        guard var record = try getRecord() else {
            throw SystemUptimeRecordError.notRecording
        }
        
        let now = Date.now
        let sleep = SystemUptimeRecord.SleepRecord(start: now, end: now)
        record.sleepRecords.append(sleep)
        try localSource.updateUptimeRecord(record)
        
        state = .sleep
    }
    
    func wake() throws {
        guard state == .sleep else {
            throw SystemUptimeRecordError.notSleeping
        }
        guard var record = try getRecord() else {
            throw SystemUptimeRecordError.notRecording
        }
        
        let index = record.sleepRecords.count - 1
        record.sleepRecords[index].end = .now
        try localSource.updateUptimeRecord(record)
        
        state = .running
    }
    
    func update() throws {
        guard var record = try getRecord() else {
            throw SystemUptimeRecordError.notRecording
        }
        
        let now = Date.now
        record.shutdown = now
        
        if state == .sleep {
            let index = record.sleepRecords.count - 1
            record.sleepRecords[index].end = now
        }
        
        try localSource.updateUptimeRecord(record)
        try saveBackup(record)
        
        if record.launch.day != now.day {
            var record = SystemUptimeRecord(launch: now, shutdown: now)
            
            if state == .sleep {
                let sleep = SystemUptimeRecord.SleepRecord(start: now, end: now)
                record.sleepRecords.append(sleep)
            }
            
            try localSource.insertUptimeRecord(record)
            try saveBackup(record)
        }
    }
    
    private func saveBackup(_ record: SystemUptimeRecord) throws {
        var records = try fileSource.getUptimeRecords()
        records.removeAll { $0.id == record.id }
        records.append(record)
        try fileSource.saveUptimeRecords(records)
    }
    
    func restoreBackup() throws {
        let records = try fileSource.getUptimeRecords()
        try records.forEach {
            if let record = try localSource.getUptimeRecord(id: $0.id) {
                if record != $0 {
                    try localSource.updateUptimeRecord($0)
                }
            } else {
                try localSource.insertUptimeRecord($0)
            }
        }
        
        try fileSource.removeUptimeRecords()
    }
}
