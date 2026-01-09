//
//  CalendarRecordRepositoryTests.swift
//  TimeCardClientIOSTests
//
//  Created by uhimania on 2026/01/06.
//

import Foundation
import Testing

@testable import TimeCardClientIOS

struct CalendarRecordRepositoryTests {

    @Test func testGetRecords() async throws {
        let network = FakeNetworkDataSource()
        let local = FakeLocalDataSource()
        let repository = DefaultCalendarRecordRepository(networkDataSource: network, localDataSource: local)
        var iterator = repository.getRecords(year: 2025, month: 12).makeAsyncIterator()
        var records = try await iterator.next()
        #expect(records?.count == 31)
        
        for i in 0..<31 {
            let record = records?[i]
            #expect(record?.date.year == 2025)
            #expect(record?.date.month == 12)
            #expect(record?.date.day == i + 1)
            
            switch i + 1 {
            case 1:
                #expect(record?.records.count == 2)
                #expect(record?.records[0] == local.records[0])
                #expect(record?.records[1] == local.records[1])
            case 2:
                #expect(record?.records.count == 1)
                #expect(record?.records[0] == local.records[2])
            default:
                #expect(record?.records.count == 0)
            }
        }
        
        #expect(local.getRecordsYear == 2025)
        #expect(local.getRecordsMonth == 12)
        
        records = try await iterator.next()
        
        for i in 0..<31 {
            let record = records?[i]
            #expect(record?.date.year == 2025)
            #expect(record?.date.month == 12)
            #expect(record?.date.day == i + 1)
            
            switch i + 1 {
            case 4:
                #expect(record?.records.count == 2)
                #expect(record?.records[0] == network.records[0])
                #expect(record?.records[1] == network.records[1])
            case 5:
                #expect(record?.records.count == 1)
                #expect(record?.records[0] == network.records[2])
            default:
                #expect(record?.records.count == 0)
            }
        }
        
        #expect(network.year == 2025)
        #expect(network.month == 12)
        
        #expect(local.deleteRecordsYear == 2025)
        #expect(local.deleteRecordsMonth == 12)
        
        #expect(local.inserted.count == 3)
        #expect(local.inserted[0] == network.records[0])
        #expect(local.inserted[1] == network.records[1])
        #expect(local.inserted[2] == network.records[2])
    }
    
    @Test func testUpdateRecord() async throws {
        let records = Calendar.current.datesOf(year: 2025, month: 12).map { date in
            CalendarRecord(
                date: date,
                records: [
                    TimeRecord(
                        id: UUID(),
                        year: date.year,
                        month: date.month,
                        checkIn: date,
                        checkOut: date,
                        breakTimes: [
                            TimeRecord.BreakTime(
                                id: UUID(),
                                start: date,
                                end: date
                            )
                        ]
                    ),
                    TimeRecord(
                        id: UUID(),
                        year: date.year,
                        month: date.month,
                        checkIn: date,
                        checkOut: date,
                        breakTimes: [
                            TimeRecord.BreakTime(
                                id: UUID(),
                                start: date,
                                end: date
                            )
                        ]
                    ),
                    TimeRecord(
                        id: UUID(),
                        year: date.year,
                        month: date.month,
                        checkIn: date,
                        checkOut: date,
                        breakTimes: [
                            TimeRecord.BreakTime(
                                id: UUID(),
                                start: date,
                                end: date
                            )
                        ]
                    )
                ]
            )
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let record = CalendarRecord(
            date: records[0].date,
            records: [
                records[0].records[1],
                TimeRecord(
                    id: records[0].records[2].id,
                    year: records[0].records[2].year,
                    month: records[0].records[2].month,
                    checkIn: formatter.date(from: "2025-12-01 12:00:00"),
                    checkOut: formatter.date(from: "2025-12-01 13:00:00"),
                    breakTimes: records[0].records[2].breakTimes
                ),
                TimeRecord(
                    id: UUID(),
                    year: records[0].date.year,
                    month: records[0].date.month,
                    checkIn: formatter.date(from: "2025-12-01 17:00:00"),
                    checkOut: formatter.date(from: "2025-12-01 18:00:00"),
                    breakTimes: [
                        TimeRecord.BreakTime(
                            id: UUID(),
                            start: formatter.date(from: "2025-12-01 17:15:00"),
                            end: formatter.date(from: "2025-12-01 17:20:00")
                        ),
                        TimeRecord.BreakTime(
                            id: UUID(),
                            start: formatter.date(from: "2025-12-01 17:45:00"),
                            end: formatter.date(from: "2025-12-01 17:50:00")
                        )
                    ]
                )
            ]
        )
        
        let network = FakeNetworkDataSource()
        let local = FakeLocalDataSource()
        let repository = DefaultCalendarRecordRepository(networkDataSource: network, localDataSource: local)
        
        // setup async stream
        var iterator = repository.getRecords(year: 2025, month: 12).makeAsyncIterator()
        var result = try await iterator.next()
        #expect(result?.count == 31)
        #expect(result?[0].records.count == 2)
        #expect(result?[1].records.count == 1)
        
        result = try await iterator.next()
        #expect(result?.count == 31)
        #expect(result?[3].records.count == 2)
        #expect(result?[4].records.count == 1)
        
        // cleanup
        local.inserted.removeAll()
        
        // run tests
        try await repository.updateRecord(source: records, record: record)
        result = try await iterator.next()
        #expect(result?.count == 31)
        
        for i in 0..<31 {
            #expect(result?[i].date == records[i].date)
            
            if i + 1 == 1 {
                #expect(result?[i].records.count == 3)
                
                #expect(result?[i].records[0] == record.records[0])
                #expect(result?[i].records[1] == record.records[1])
                
                #expect(result?[i].records[2].id == network.insertedId.id)
                #expect(result?[i].records[2].year == record.records[2].year)
                #expect(result?[i].records[2].month == record.records[2].month)
                #expect(result?[i].records[2].checkIn == record.records[2].checkIn)
                #expect(result?[i].records[2].checkOut == record.records[2].checkOut)
                
                #expect(result?[i].records[2].breakTimes.count == 2)
                #expect(result?[i].records[2].breakTimes[0].id == network.insertedId.breakTimes[0].id)
                #expect(result?[i].records[2].breakTimes[0].start == record.records[2].breakTimes[0].start)
                #expect(result?[i].records[2].breakTimes[0].end == record.records[2].breakTimes[0].end)
                #expect(result?[i].records[2].breakTimes[1].start == record.records[2].breakTimes[1].start)
                #expect(result?[i].records[2].breakTimes[1].end == record.records[2].breakTimes[1].end)
            } else {
                #expect(result?[i].records == records[i].records)
            }
        }
        
        #expect(network.inserted.count == 1)
        #expect(network.inserted[0] == record.records[2])
        #expect(network.updated.count == 1)
        #expect(network.updated[0] == record.records[1])
        #expect(network.deleted.count == 1)
        #expect(network.deleted[0] == records[0].records[0])
        
        #expect(local.inserted.count == 1)
        #expect(local.inserted[0] == result?[0].records[2])
        #expect(local.updated.count == 1)
        #expect(local.updated[0] == result?[0].records[1])
        #expect(local.deleted.count == 1)
        #expect(local.deleted[0] == records[0].records[0])
    }

    class FakeNetworkDataSource: NetworkDataSource {
        let records: [TimeRecord]
        
        init() {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            records = [
                TimeRecord(
                    id: UUID(),
                    year: 2025,
                    month: 12,
                    checkIn: formatter.date(from: "2025-12-04 09:00:00"),
                    checkOut: formatter.date(from: "2025-12-04 19:00:00"),
                    breakTimes: [
                        TimeRecord.BreakTime(
                            id: UUID(),
                            start: formatter.date(from: "2025-12-04 12:00:00"),
                            end: formatter.date(from: "2025-12-04 12:45:00")
                        ),
                        TimeRecord.BreakTime(
                            id: UUID(),
                            start: formatter.date(from: "2025-12-04 17:30:00"),
                            end: formatter.date(from: "2025-12-04 18:00:00")
                        )
                    ]
                ),
                TimeRecord(
                    id: UUID(),
                    year: 2025,
                    month: 12,
                    checkIn: formatter.date(from: "2025-12-04 22:00:00"),
                    checkOut: formatter.date(from: "2025-12-05 01:00:00"),
                    breakTimes: [
                        TimeRecord.BreakTime(
                            id: UUID(),
                            start: formatter.date(from: "2025-12-04 23:00:00"),
                            end: formatter.date(from: "2025-12-05 00:30:00")
                        )
                    ]
                ),
                TimeRecord(
                    id: UUID(),
                    year: 2025,
                    month: 12,
                    checkIn: formatter.date(from: "2025-12-05 08:30:00"),
                    checkOut: formatter.date(from: "2025-12-05 17:30:00"),
                    breakTimes: []
                )
            ]
        }
        
        var year: Int = 0
        var month: Int = 0
        func getRecords(year: Int, month: Int) async throws -> [TimeRecord] {
            self.year = year
            self.month = month
            return records
        }
        
        var inserted: [TimeRecord] = []
        let insertedId = TimeRecord(
            id: UUID(),
            year: 0,
            month: 0,
            breakTimes: [
                TimeRecord.BreakTime(
                    id: UUID()
                ),
                TimeRecord.BreakTime(
                    id: UUID()
                )
            ]
        )
        func insertRecord(record: TimeRecord) async throws -> TimeRecord {
            inserted.append(record)
            return TimeRecord(
                id: insertedId.id,
                year: record.year,
                month: record.month,
                checkIn: record.checkIn,
                checkOut: record.checkOut,
                breakTimes: [
                    TimeRecord.BreakTime(
                        id: insertedId.breakTimes[0].id,
                        start: record.breakTimes[0].start,
                        end: record.breakTimes[0].end
                    ),
                    TimeRecord.BreakTime(
                        id: insertedId.breakTimes[1].id,
                        start: record.breakTimes[1].start,
                        end: record.breakTimes[1].end
                    )
                ]
            )
        }
        
        var updated: [TimeRecord] = []
        func updateRecord(record: TimeRecord) async throws -> TimeRecord {
            updated.append(record)
            return record
        }
        
        var deleted: [TimeRecord] = []
        func deleteRecord(record: TimeRecord) async throws {
            deleted.append(record)
        }
    }
    
    class FakeLocalDataSource: LocalDataSource {
        let records: [TimeRecord]
        
        init() {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            records = [
                TimeRecord(
                    id: UUID(),
                    year: 2025,
                    month: 12,
                    checkIn: formatter.date(from: "2025-12-01 09:00:00"),
                    checkOut: formatter.date(from: "2025-12-01 19:00:00"),
                    breakTimes: [
                        TimeRecord.BreakTime(
                            id: UUID(),
                            start: formatter.date(from: "2025-12-01 12:00:00"),
                            end: formatter.date(from: "2025-12-01 12:45:00")
                        ),
                        TimeRecord.BreakTime(
                            id: UUID(),
                            start: formatter.date(from: "2025-12-01 17:30:00"),
                            end: formatter.date(from: "2025-12-01 18:00:00")
                        )
                    ]
                ),
                TimeRecord(
                    id: UUID(),
                    year: 2025,
                    month: 12,
                    checkIn: formatter.date(from: "2025-12-01 22:00:00"),
                    checkOut: formatter.date(from: "2025-12-02 01:00:00"),
                    breakTimes: [
                        TimeRecord.BreakTime(
                            id: UUID(),
                            start: formatter.date(from: "2025-12-01 23:00:00"),
                            end: formatter.date(from: "2025-12-02 00:30:00")
                        )
                    ]
                ),
                TimeRecord(
                    id: UUID(),
                    year: 2025,
                    month: 12,
                    checkIn: formatter.date(from: "2025-12-02 08:30:00"),
                    checkOut: formatter.date(from: "2025-12-02 17:30:00"),
                    breakTimes: []
                )
            ]
        }
        
        var getRecordsYear: Int = 0
        var getRecordsMonth: Int = 0
        func getRecords(year: Int, month: Int) throws -> [TimeRecord] {
            getRecordsYear = year
            getRecordsMonth = month
            return records
        }
        
        var inserted: [TimeRecord] = []
        func insertRecord(record: TimeRecord) throws {
            inserted.append(record)
        }
        
        var updated: [TimeRecord] = []
        func updateRecord(record: TimeRecord) throws {
            updated.append(record)
        }
        
        var deleted: [TimeRecord] = []
        func deleteRecord(record: TimeRecord) throws {
            deleted.append(record)
        }
        
        var deleteRecordsYear: Int = 0
        var deleteRecordsMonth: Int = 0
        func deleteRecords(year: Int, month: Int) throws {
            deleteRecordsYear = year
            deleteRecordsMonth = month
        }
    }
}
