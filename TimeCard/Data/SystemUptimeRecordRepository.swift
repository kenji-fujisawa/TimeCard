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
    
    private let source: LocalDataSource
    private var state: State = .shutdown
    
    init(source: LocalDataSource) {
        self.source = source
    }
    
    private func getRecord() throws -> SystemUptimeRecord? {
        let now = Date.now
        return try source.getUptimeRecords(year: now.year, month: now.month).last
    }
    
    func launch() throws {
        guard state == .shutdown else {
            throw SystemUptimeRecordError.alreadyRecording
        }
        
        let now = Date.now
        let record = SystemUptimeRecord(
            year: now.year,
            month: now.month,
            day: now.day,
            launch: now,
            shutdown: now,
            sleepRecords: []
        )
        try source.insertUptimeRecord(record: record)
        
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
        
        try source.updateUptimeRecord(record: record)
        
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
        try source.updateUptimeRecord(record: record)
        
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
        try source.updateUptimeRecord(record: record)
        
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
        
        try source.updateUptimeRecord(record: record)
        
        if record.day != now.day {
            var record = SystemUptimeRecord(
                year: now.year,
                month: now.month,
                day: now.day,
                launch: now,
                shutdown: now
            )
            
            if state == .sleep {
                let sleep = SystemUptimeRecord.SleepRecord(start: now, end: now)
                record.sleepRecords.append(sleep)
            }
            
            try source.insertUptimeRecord(record: record)
        }
    }
}
