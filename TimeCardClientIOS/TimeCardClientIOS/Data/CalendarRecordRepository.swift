//
//  CalendarRecordRepository.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2026/01/06.
//

import Foundation

protocol CalendarRecordRepository {
    func getRecordsStream(year: Int, month: Int) -> AsyncThrowingStream<[CalendarRecord], Error>
    func updateRecord(_ record: CalendarRecord) async throws
}

class DefaultCalendarRecordRepository: CalendarRecordRepository {
    private var networkDataSource: NetworkDataSource
    private var localDataSource: LocalDataSource
    private var publish: (([CalendarRecord]) -> Void)?
    
    init(_ networkDataSource: NetworkDataSource, _ localDataSource: LocalDataSource) {
        self.networkDataSource = networkDataSource
        self.localDataSource = localDataSource
    }
    
    func getRecordsStream(year: Int, month: Int) -> AsyncThrowingStream<[CalendarRecord], Error> {
        return AsyncThrowingStream { continuation in
            publish = { records in
                continuation.yield(records)
            }
            
            do {
                try publishRecords(year: year, month: month)
            } catch {
                continuation.finish(throwing: error)
            }
            
            Task {
                do {
                    let records = try await networkDataSource.getRecords(year: year, month: month)
                    
                    try localDataSource.deleteRecords(year: year, month: month)
                    try records.forEach { try localDataSource.insertRecord($0) }
                    
                    try publishRecords(year: year, month: month)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func publishRecords(year: Int, month: Int) throws {
        let records = try localDataSource.getRecords(year: year, month: month)
        
        var timeRecords: [Int: [TimeRecord]] = [:]
        records.forEach { rec in
            if let day = rec.checkIn?.day {
                if timeRecords[day] == nil {
                    timeRecords[day] = []
                }
                timeRecords[day]?.append(rec)
            }
        }
        
        var results: [CalendarRecord] = []
        let dates = Calendar.current.datesOf(year: year, month: month)
        dates.forEach { date in
            results.append(CalendarRecord(date: date, records: timeRecords[date.day] ?? []))
        }
        
        publish?(results)
    }
    
    func updateRecord(_ record: CalendarRecord) async throws {
        let year = record.date.year
        let month = record.date.month
        let day = record.date.day
        let original = try localDataSource.getRecords(year: year, month: month).filter { $0.checkIn?.day == day }
        
        let inserted = record.records.filter { rec in
            !original.contains(where: { $0.id == rec.id })
        }
        let updated = record.records.filter { rec in
            let before = original.first(where: { $0.id == rec.id })
            return before != nil && before != rec
        }
        let deleted = original.filter { rec in
            !record.records.contains(where: { $0.id == rec.id })
        }
        
        for rec in inserted {
            let result = try await networkDataSource.insertRecord(rec)
            try localDataSource.insertRecord(result)
        }
        for rec in updated {
            let result = try await networkDataSource.updateRecord(rec)
            try localDataSource.updateRecord(result)
        }
        for rec in deleted {
            try await networkDataSource.deleteRecord(rec)
            try localDataSource.deleteRecord(rec)
        }
        
        try publishRecords(year: year, month: month)
    }
}
