//
//  CalendarRecordRepositoryTests.swift
//  TimeCardClientIOSTests
//
//  Created by uhimania on 2026/01/06.
//

import Foundation
import SwiftData
import Testing

@testable import TimeCardClientIOS

@Suite(.serialized)
struct CalendarRecordRepositoryTests {

    @Test func testGetRecordsStream() async throws {
        let network = FakeNetworkDataSource()
        let local = try FakeLocalDataSource()
        try local.initForGet()
        
        let localRecords = local.records
        
        let repository = DefaultCalendarRecordRepository(network, local)
        var iterator = repository.getRecordsStream(year: 2025, month: 12).makeAsyncIterator()
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
                #expect(record?.records[0] == localRecords[0])
                #expect(record?.records[1] == localRecords[1])
            case 2:
                #expect(record?.records.count == 1)
                #expect(record?.records[0] == localRecords[2])
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
        
        let localRecs = try local.getRecords(year: 2025, month: 12)
        let netRecs = try await network.getRecords(year: 2025, month: 12)
        #expect(localRecs == netRecs)
    }
    
    @Test func testGetRecordsStream_multiStream() async throws {
        let network = FakeNetworkDataSource()
        let local = try FakeLocalDataSource()
        try local.initForGet()
        
        let repository = DefaultCalendarRecordRepository(network, local)
        var iterator1 = repository.getRecordsStream(year: 2025, month: 12).makeAsyncIterator()
        var iterator2 = repository.getRecordsStream(year: 2025, month: 12).makeAsyncIterator()
        var records = try await iterator1.next()
        #expect(records?.count == 31)
        
        records = try await iterator2.next()
        #expect(records?.count == 31)
        
        records = try await iterator1.next()
        #expect(records?.count == 31)
        
        records = try await iterator2.next()
        #expect(records?.count == 31)
    }
    
    @Test func testGetRecord() async throws {
        let network = FakeNetworkDataSource()
        let local = try FakeLocalDataSource()
        try local.initForGet()
        
        let repository = DefaultCalendarRecordRepository(network, local)
        
        var record = try repository.getRecord(year: 2025, month: 12, day: 1)
        #expect(record.date.year == 2025)
        #expect(record.date.month == 12)
        #expect(record.date.day == 1)
        #expect(record.records.count == 2)
        #expect(record.records[0] == local.records[0])
        #expect(record.records[1] == local.records[1])
        
        record = try repository.getRecord(year: 2025, month: 12, day: 2)
        #expect(record.date.year == 2025)
        #expect(record.date.month == 12)
        #expect(record.date.day == 2)
        #expect(record.records.count == 1)
        #expect(record.records[0] == local.records[2])
        
        record = try repository.getRecord(year: 2025, month: 12, day: 3)
        #expect(record.date.year == 2025)
        #expect(record.date.month == 12)
        #expect(record.date.day == 3)
        #expect(record.records.count == 0)
    }
    
    @Test func testUpdateRecord() async throws {
        let network = FakeNetworkDataSource()
        let local = try FakeLocalDataSource()
        try local.initForUpdate()
        
        let localRecords = local.records
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let record = CalendarRecord(
            date: formatter.date(from: "2025-12-01 00:00:00") ?? .now,
            records: [
                local.records[1],
                TimeRecord(
                    id: local.records[2].id,
                    checkIn: formatter.date(from: "2025-12-01 12:00:00"),
                    checkOut: formatter.date(from: "2025-12-01 13:00:00"),
                    breakTimes: local.records[2].breakTimes
                ),
                TimeRecord(
                    id: UUID(),
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
        
        let repository = DefaultCalendarRecordRepository(network, local)
        
        // setup async stream
        var iterator = repository.getRecordsStream(year: 2025, month: 12).makeAsyncIterator()
        var result = try await iterator.next()
        #expect(result?.count == 31)
        #expect(result?[0].records.count == 3)
        
        result = try await iterator.next()
        #expect(result?.count == 31)
        #expect(result?[3].records.count == 2)
        #expect(result?[4].records.count == 1)
        
        // cleanup
        try local.deleteRecords(year: 2025, month: 12)
        try localRecords.forEach { try local.insertRecord($0) }
        local.deleteRecordsYear = 0
        local.deleteRecordsMonth = 0
        local.inserted.removeAll()
        
        result = try await iterator.next()
        result = try await iterator.next()
        result = try await iterator.next()
        result = try await iterator.next()
        #expect(result?.count == 31)
        #expect(result?[0].records.count == 3)
        
        // run tests
        try await repository.updateRecord(record)
        result = try await iterator.next()
        result = try await iterator.next()
        result = try await iterator.next()
        #expect(result?.count == 31)
        #expect(result?[0].records.count == 3)
        
        for i in 0..<31 {
            #expect(result?[i].date.year == 2025)
            #expect(result?[i].date.month == 12)
            #expect(result?[i].date.day == i + 1)
            
            if i + 1 == 1 {
                #expect(result?[i].records.count == 3)
                
                #expect(result?[i].records[0] == record.records[0])
                #expect(result?[i].records[1] == record.records[1])
                
                #expect(result?[i].records[2].id == network.insertedId.id)
                #expect(result?[i].records[2].checkIn == record.records[2].checkIn)
                #expect(result?[i].records[2].checkOut == record.records[2].checkOut)
                
                #expect(result?[i].records[2].breakTimes.count == 2)
                #expect(result?[i].records[2].breakTimes[0].id == network.insertedId.breakTimes[0].id)
                #expect(result?[i].records[2].breakTimes[0].start == record.records[2].breakTimes[0].start)
                #expect(result?[i].records[2].breakTimes[0].end == record.records[2].breakTimes[0].end)
                #expect(result?[i].records[2].breakTimes[1].start == record.records[2].breakTimes[1].start)
                #expect(result?[i].records[2].breakTimes[1].end == record.records[2].breakTimes[1].end)
            } else {
                #expect(result?[i].records.count == 0)
            }
        }
        
        #expect(network.inserted.count == 1)
        #expect(network.inserted[0] == record.records[2])
        #expect(network.updated.count == 1)
        #expect(network.updated[0] == record.records[1])
        #expect(network.deleted.count == 1)
        #expect(network.deleted[0] == localRecords[0])
        
        #expect(local.inserted.count == 1)
        #expect(local.inserted[0] == result?[0].records[2])
        #expect(local.updated.count == 1)
        #expect(local.updated[0] == result?[0].records[1])
        #expect(local.deleted.count == 1)
        #expect(local.deleted[0] == localRecords[0])
    }

    class FakeNetworkDataSource: NetworkDataSource {
        let records: [TimeRecord]
        
        init() {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            records = [
                TimeRecord(
                    id: UUID(),
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
            breakTimes: [
                TimeRecord.BreakTime(
                    id: UUID()
                ),
                TimeRecord.BreakTime(
                    id: UUID()
                )
            ]
        )
        func insertRecord(_ record: TimeRecord) async throws -> TimeRecord {
            inserted.append(record)
            return TimeRecord(
                id: insertedId.id,
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
        func updateRecord(_ record: TimeRecord) async throws -> TimeRecord {
            updated.append(record)
            return record
        }
        
        var deleted: [TimeRecord] = []
        func deleteRecord(_ record: TimeRecord) async throws {
            deleted.append(record)
        }
    }
    
    class FakeLocalDataSource: DefaultLocalDataSource {
        var records: [TimeRecord] = []
        
        init() throws {
            let schema = Schema([LocalTimeRecord.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: config)
            let context = ModelContext(container)
            super.init(context)
        }
        
        func initForGet() throws {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            records = [
                TimeRecord(
                    id: UUID(),
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
                    checkIn: formatter.date(from: "2025-12-02 08:30:00"),
                    checkOut: formatter.date(from: "2025-12-02 17:30:00"),
                    breakTimes: []
                )
            ]
            try records.forEach { try super.insertRecord($0) }
        }
        
        func initForUpdate() throws {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let date = formatter.date(from: "2025-12-01 00:00:00") ?? .now
            
            for _ in 1...3 {
                records.append(
                    TimeRecord(
                        id: UUID(),
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
                )
            }
            try records.forEach { try super.insertRecord($0) }
        }
        
        var getRecordsYear: Int = 0
        var getRecordsMonth: Int = 0
        override func getRecords(year: Int, month: Int) throws -> [TimeRecord] {
            getRecordsYear = year
            getRecordsMonth = month
            return try super.getRecords(year: year, month: month)
        }
        
        var inserted: [TimeRecord] = []
        override func insertRecord(_ record: TimeRecord) throws {
            inserted.append(record)
            try super.insertRecord(record)
        }
        
        var updated: [TimeRecord] = []
        override func updateRecord(_ record: TimeRecord) throws {
            updated.append(record)
            try super.updateRecord(record)
        }
        
        var deleted: [TimeRecord] = []
        override func deleteRecord(_ record: TimeRecord) throws {
            deleted.append(record)
            try super.deleteRecord(record)
        }
        
        var deleteRecordsYear: Int = 0
        var deleteRecordsMonth: Int = 0
        override func deleteRecords(year: Int, month: Int) throws {
            deleteRecordsYear = year
            deleteRecordsMonth = month
            try super.deleteRecords(year: year, month: month)
        }
    }
}
