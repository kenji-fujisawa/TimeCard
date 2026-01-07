//
//  CalendarRecordRepository.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2026/01/06.
//

import Foundation

protocol CalendarRecordRepository {
    func getRecords(year: Int, month: Int) async throws -> [CalendarRecord]
    func updateRecord(source: [CalendarRecord], record: CalendarRecord) async throws -> [CalendarRecord]
}

class DefaultCalendarRecordRepository: CalendarRecordRepository {
    private var networkDataSource: NetworkDataSource
    
    init(networkDataSource: NetworkDataSource) {
        self.networkDataSource = networkDataSource
    }
    
    func getRecords(year: Int, month: Int) async throws -> [CalendarRecord] {
        let records = try await networkDataSource.getRecords(year: year, month: month)
        
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
    
    func updateRecord(source: [CalendarRecord], record: CalendarRecord) async throws -> [CalendarRecord] {
        guard let original = source.first(where: { $0.date == record.date }) else {
            return source
        }
        
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
        }
        for rec in updated {
            let result = try await networkDataSource.updateRecord(record: rec)
            results.append(result)
        }
        for rec in deleted {
            try await networkDataSource.deleteRecord(record: rec)
        }
        
        results.sort(by: { $0.checkIn ?? .distantPast < $1.checkIn ?? .distantPast })
        
        return source.map { rec in
            rec.date != record.date ? rec : CalendarRecord(
                date: rec.date,
                records: results
            )
        }
    }
}
