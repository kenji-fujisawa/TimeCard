//
//  CalendarRecordRepository.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2026/01/06.
//

import Foundation

protocol CalendarRecordRepository {
    func getRecords(year: Int, month: Int) -> AsyncThrowingStream<[CalendarRecord], Error>
    func updateRecord(source: [CalendarRecord], record: CalendarRecord) async throws
}

class DefaultCalendarRecordRepository: CalendarRecordRepository {
    private var networkDataSource: NetworkDataSource
    private var localDataSource: LocalDataSource
    private var publishRecord: (([CalendarRecord]) -> Void)?
    
    init(networkDataSource: NetworkDataSource, localDataSource: LocalDataSource) {
        self.networkDataSource = networkDataSource
        self.localDataSource = localDataSource
    }
    
    func getRecords(year: Int, month: Int) -> AsyncThrowingStream<[CalendarRecord], Error> {
        let toCalendarRecord = { (records: [TimeRecord]) in
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
            
            return results
        }
        
        return AsyncThrowingStream { continuation in
            publishRecord = { records in
                continuation.yield(records)
            }
            
            do {
                let records = try localDataSource.getRecords(year: year, month: month)
                continuation.yield(toCalendarRecord(records))
            } catch {
                continuation.finish(throwing: error)
            }
            
            Task {
                do {
                    let records = try await networkDataSource.getRecords(year: year, month: month)
                    
                    try localDataSource.deleteRecords(year: year, month: month)
                    try records.forEach { try localDataSource.insertRecord(record: $0) }
                    
                    continuation.yield(toCalendarRecord(records))
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func updateRecord(source: [CalendarRecord], record: CalendarRecord) async throws {
        guard let original = source.first(where: { $0.date == record.date }) else { return }
        
        let inserted = record.records.filter { rec in
            !original.records.contains(where: { $0.id == rec.id })
        }
        let updated = record.records.filter { rec in
            let before = original.records.first(where: { $0.id == rec.id })
            return before != nil && before != rec
        }
        let deleted = original.records.filter { rec in
            !record.records.contains(where: { $0.id == rec.id })
        }
        let notChanged = record.records.filter { rec in
            let before = original.records.first(where: { $0.id == rec.id })
            return before != nil && before == rec
        }
        
        var results = notChanged
        
        for rec in inserted {
            let result = try await networkDataSource.insertRecord(record: rec)
            results.append(result)
            try localDataSource.insertRecord(record: result)
        }
        for rec in updated {
            let result = try await networkDataSource.updateRecord(record: rec)
            results.append(result)
            try localDataSource.updateRecord(record: result)
        }
        for rec in deleted {
            try await networkDataSource.deleteRecord(record: rec)
            try localDataSource.deleteRecord(record: rec)
        }
        
        results.sort(by: { $0.checkIn ?? .distantPast < $1.checkIn ?? .distantPast })
        
        publishRecord?(source.map { rec in
            rec.date != record.date ? rec : CalendarRecord(
                date: rec.date,
                records: results
            )
        })
    }
}
