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
    
    private let source: LocalDataSource
    private var record: SystemUptimeRecord? = nil
    private var sleepRecord: SystemUptimeRecord.SleepRecord? = nil
    
    init(source: LocalDataSource) {
        self.source = source
    }
    
    func launch() throws {
        guard record == nil else {
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
        self.record = record
    }
    
    func shutdown() throws {
        guard let record = self.record else {
            throw SystemUptimeRecordError.notRecording
        }
        
        record.shutdown = .now
        self.record = nil
        
        self.sleepRecord?.end = .now
        self.sleepRecord = nil
    }
    
    func sleep() throws {
        guard let record = self.record else {
            throw SystemUptimeRecordError.notRecording
        }
        guard sleepRecord == nil else {
            throw SystemUptimeRecordError.alreadySleeping
        }
        
        let now = Date.now
        let sleep = SystemUptimeRecord.SleepRecord(start: now, end: now)
        record.sleepRecords.append(sleep)
        self.sleepRecord = sleep
    }
    
    func wake() throws {
        guard record != nil else {
            throw SystemUptimeRecordError.notRecording
        }
        guard let sleep = self.sleepRecord else {
            throw SystemUptimeRecordError.notSleeping
        }
        
        sleep.end = .now
        self.sleepRecord = nil
    }
    
    func update() throws {
        guard let record = self.record else {
            throw SystemUptimeRecordError.notRecording
        }
        
        let now = Date.now
        record.shutdown = now
        self.sleepRecord?.end = now
        
        if record.day != now.day {
            let record = SystemUptimeRecord(
                year: now.year,
                month: now.month,
                day: now.day,
                launch: now,
                shutdown: now
            )
            try source.insertUptimeRecord(record: record)
            self.record = record
            
            if self.sleepRecord != nil {
                let sleep = SystemUptimeRecord.SleepRecord(start: now, end: now)
                record.sleepRecords.append(sleep)
                self.sleepRecord = sleep
            }
        }
    }
}
