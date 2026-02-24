//
//  CalendarRecordRepositoryTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2026/01/13.
//

import Foundation
import SwiftData
import Testing

@testable import TimeCard

struct CalendarRecordRepositoryTests {

    @Test func testGetRecords() async throws {
        let source = FakeLocalDataSource()
        let repository = DefaultCalendarRecordRepository(source: source)
        var iterator = repository.getRecords(year: 2025, month: 12).makeAsyncIterator()
        let records = await iterator.next()
        #expect(records?.count == 31)
        
        for i in 0..<31 {
            let record = records?[i]
            #expect(record?.date.year == 2025)
            #expect(record?.date.month == 12)
            #expect(record?.date.day == i + 1)
            
            switch i + 1 {
            case 4:
                #expect(record?.records.count == 2)
                #expect(record?.records[0] == source.timeRecords[0])
                #expect(record?.records[1] == source.timeRecords[1])
                #expect(record?.timeWorked == source.timeRecords[0].timeWorked + source.timeRecords[1].timeWorked)
                
                #expect(record?.systemUptimeRecords.count == 2)
                #expect(record?.systemUptimeRecords[0] == source.uptimeRecords[0])
                #expect(record?.systemUptimeRecords[1] == source.uptimeRecords[1])
                #expect(record?.systemUptime == source.uptimeRecords[0].uptimes + source.uptimeRecords[1].uptimes)
            case 5:
                #expect(record?.records.count == 1)
                #expect(record?.records[0] == source.timeRecords[2])
                #expect(record?.timeWorked == source.timeRecords[2].timeWorked)
                
                #expect(record?.systemUptimeRecords.count == 1)
                #expect(record?.systemUptimeRecords[0] == source.uptimeRecords[2])
                #expect(record?.systemUptime == source.uptimeRecords[2].uptimes)
            default:
                #expect(record?.records.count == 0)
                #expect(record?.timeWorked == 0)
                
                #expect(record?.systemUptimeRecords.count == 0)
                #expect(record?.systemUptime == 0)
            }
        }
        
        NotificationCenter.default.post(name: ModelContext.didSave, object: nil)
        
        let records2 = await iterator.next()
        #expect(records?.count == records2?.count)
        
        for i in 0..<31 {
            #expect(records?[i].records == records2?[i].records)
            #expect(records?[i].systemUptimeRecords == records2?[i].systemUptimeRecords)
        }
    }
    
    @Test func testUpdateRecord() async throws {
        let records = Calendar.current.datesOf(year: 2025, month: 12).map { date in
            CalendarRecord(
                date: date,
                records: [
                    TimeRecord(
                        year: date.year,
                        month: date.month,
                        checkIn: date,
                        checkOut: date,
                        breakTimes: [
                            TimeRecord.BreakTime(
                                start: date,
                                end: date
                            )
                        ]
                    ),
                    TimeRecord(
                        year: date.year,
                        month: date.month,
                        checkIn: date,
                        checkOut: date,
                        breakTimes: [
                            TimeRecord.BreakTime(
                                start: date,
                                end: date
                            )
                        ]
                    ),
                    TimeRecord(
                        year: date.year,
                        month: date.month,
                        checkIn: date,
                        checkOut: date,
                        breakTimes: [
                            TimeRecord.BreakTime(
                                start: date,
                                end: date
                            )
                        ]
                    )
                ],
                systemUptimeRecords: [
                    SystemUptimeRecord(
                        year: date.year,
                        month: date.month,
                        day: date.day,
                        launch: date,
                        shutdown: date,
                        sleepRecords: [
                            SystemUptimeRecord.SleepRecord(
                                start: date,
                                end: date
                            )
                        ]
                    ),
                    SystemUptimeRecord(
                        year: date.year,
                        month: date.month,
                        day: date.day,
                        launch: date,
                        shutdown: date,
                        sleepRecords: [
                            SystemUptimeRecord.SleepRecord(
                                start: date,
                                end: date
                            )
                        ]
                    ),
                    SystemUptimeRecord(
                        year: date.year,
                        month: date.month,
                        day: date.day,
                        launch: date,
                        shutdown: date,
                        sleepRecords: [
                            SystemUptimeRecord.SleepRecord(
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
                    year: records[0].date.year,
                    month: records[0].date.month,
                    checkIn: formatter.date(from: "2025-12-01 17:00:00"),
                    checkOut: formatter.date(from: "2025-12-01 18:00:00"),
                    breakTimes: [
                        TimeRecord.BreakTime(
                            start: formatter.date(from: "2025-12-01 17:15:00"),
                            end: formatter.date(from: "2025-12-01 17:20:00")
                        ),
                        TimeRecord.BreakTime(
                            start: formatter.date(from: "2025-12-01 17:45:00"),
                            end: formatter.date(from: "2025-12-01 17:50:00")
                        )
                    ]
                )
            ],
            systemUptimeRecords: [
                records[0].systemUptimeRecords[1],
                SystemUptimeRecord(
                    id: records[0].systemUptimeRecords[2].id,
                    year: records[0].systemUptimeRecords[2].year,
                    month: records[0].systemUptimeRecords[2].month,
                    day: records[0].systemUptimeRecords[2].day,
                    launch: formatter.date(from: "2025-12-01 12:00:00") ?? .now,
                    shutdown: formatter.date(from: "2025-12-01 13:00:00") ?? .now,
                    sleepRecords: records[0].systemUptimeRecords[2].sleepRecords
                ),
                SystemUptimeRecord(
                    year: records[0].date.year,
                    month: records[0].date.month,
                    day: records[0].date.day,
                    launch: formatter.date(from: "2025-12-01 17:00:00") ?? .now,
                    shutdown: formatter.date(from: "2025-12-01 18:00:00") ?? .now,
                    sleepRecords: [
                        SystemUptimeRecord.SleepRecord(
                            start: formatter.date(from: "2025-12-01 17:15:00") ?? .now,
                            end: formatter.date(from: "2025-12-01 17:20:00") ?? .now
                        ),
                        SystemUptimeRecord.SleepRecord(
                            start: formatter.date(from: "2025-12-01 17:45:00") ?? .now,
                            end: formatter.date(from: "2025-12-01 17:50:00") ?? .now
                        )
                    ]
                )
            ]
        )
        
        let source = FakeLocalDataSource()
        let repository = DefaultCalendarRecordRepository(source: source)
        
        try repository.updateRecord(source: records, record: record)
        
        #expect(source.timeInserted.count == 1)
        #expect(source.timeInserted[0] == record.records[2])
        #expect(source.timeUpdated.count == 1)
        #expect(source.timeUpdated[0] == record.records[1])
        #expect(source.timeDeleted.count == 1)
        #expect(source.timeDeleted[0] == records[0].records[0])
        
        #expect(source.uptimeInserted.count == 1)
        #expect(source.uptimeInserted[0] == record.systemUptimeRecords[2])
        #expect(source.uptimeUpdated.count == 1)
        #expect(source.uptimeUpdated[0] == record.systemUptimeRecords[1])
        #expect(source.uptimeDeleted.count == 1)
        #expect(source.uptimeDeleted[0] == records[0].systemUptimeRecords[0])
    }
    
    class FakeLocalDataSource: LocalDataSource {
        let timeRecords: [TimeRecord]
        let uptimeRecords: [SystemUptimeRecord]
        
        init() {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            timeRecords = [
                TimeRecord(
                    year: 2025,
                    month: 12,
                    checkIn: formatter.date(from: "2025-12-04 09:00:00"),
                    checkOut: formatter.date(from: "2025-12-04 19:00:00"),
                    breakTimes: [
                        TimeRecord.BreakTime(
                            start: formatter.date(from: "2025-12-04 12:00:00"),
                            end: formatter.date(from: "2025-12-04 12:45:00")
                        ),
                        TimeRecord.BreakTime(
                            start: formatter.date(from: "2025-12-04 17:30:00"),
                            end: formatter.date(from: "2025-12-04 18:00:00")
                        )
                    ]
                ),
                TimeRecord(
                    year: 2025,
                    month: 12,
                    checkIn: formatter.date(from: "2025-12-04 22:00:00"),
                    checkOut: formatter.date(from: "2025-12-05 01:00:00"),
                    breakTimes: [
                        TimeRecord.BreakTime(
                            start: formatter.date(from: "2025-12-04 23:00:00"),
                            end: formatter.date(from: "2025-12-05 00:30:00")
                        )
                    ]
                ),
                TimeRecord(
                    year: 2025,
                    month: 12,
                    checkIn: formatter.date(from: "2025-12-05 08:30:00"),
                    checkOut: formatter.date(from: "2025-12-05 17:30:00"),
                    breakTimes: []
                )
            ]
            
            uptimeRecords = [
                SystemUptimeRecord(
                    year: 2025,
                    month: 12,
                    day: 4,
                    launch: formatter.date(from: "2025-12-04 08:00:00") ?? .now,
                    shutdown: formatter.date(from: "2025-12-04 20:00:00") ?? .now,
                    sleepRecords: [
                        SystemUptimeRecord.SleepRecord(
                            start: formatter.date(from: "2025-12-04 12:00:00") ?? .now,
                            end: formatter.date(from: "2025-12-04 13:00:00") ?? .now
                        ),
                        SystemUptimeRecord.SleepRecord(
                            start: formatter.date(from: "2025-12-04 17:00:00") ?? .now,
                            end: formatter.date(from: "2025-12-04 18:00:00") ?? .now
                        )
                    ]
                ),
                SystemUptimeRecord(
                    year: 2025,
                    month: 12,
                    day: 4,
                    launch: formatter.date(from: "2025-12-04 21:30:00") ?? .now,
                    shutdown: formatter.date(from: "2025-12-05 01:30:00") ?? .now,
                    sleepRecords: [
                        SystemUptimeRecord.SleepRecord(
                            start: formatter.date(from: "2025-12-04 23:00:00") ?? .now,
                            end: formatter.date(from: "2025-12-05 00:30:00") ?? .now
                        )
                    ]
                ),
                SystemUptimeRecord(
                    year: 2025,
                    month: 12,
                    day: 5,
                    launch: formatter.date(from: "2025-12-05 08:00:00") ?? .now,
                    shutdown: formatter.date(from: "2025-12-05 18:00:00") ?? .now,
                    sleepRecords: []
                )
            ]
        }
        
        func getTimeRecords(year: Int, month: Int) throws -> [TimeRecord] {
            timeRecords
        }
        
        var timeInserted: [TimeRecord] = []
        func insertTimeRecord(record: TimeRecord) throws {
            timeInserted.append(record)
        }
        
        var timeUpdated: [TimeRecord] = []
        func updateTimeRecord(record: TimeRecord) throws {
            timeUpdated.append(record)
        }
        
        var timeDeleted: [TimeRecord] = []
        func deleteTimeRecord(record: TimeRecord) throws {
            timeDeleted.append(record)
        }
        
        func getUptimeRecords(year: Int, month: Int) throws -> [SystemUptimeRecord] {
            uptimeRecords
        }
        
        var uptimeInserted: [SystemUptimeRecord] = []
        func insertUptimeRecord(record: SystemUptimeRecord) throws {
            uptimeInserted.append(record)
        }
        
        var uptimeUpdated: [SystemUptimeRecord] = []
        func updateUptimeRecord(record: SystemUptimeRecord) throws {
            uptimeUpdated.append(record)
        }
        
        var uptimeDeleted: [SystemUptimeRecord] = []
        func deleteUptimeRecord(record: SystemUptimeRecord) throws {
            uptimeDeleted.append(record)
        }
    }
}
