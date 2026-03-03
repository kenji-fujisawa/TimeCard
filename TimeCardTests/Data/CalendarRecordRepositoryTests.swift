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
        source.initForGet()
        
        let repository = DefaultCalendarRecordRepository(source)
        var iterator = repository.getRecordsStream(year: 2025, month: 12).makeAsyncIterator()
        let records = await iterator.next()
        #expect(records?.count == 31)
        
        for i in 0..<31 {
            let record = records?[i]
            #expect(record?.date.year == 2025)
            #expect(record?.date.month == 12)
            #expect(record?.date.day == i + 1)
            
            switch i + 1 {
            case 4:
                #expect(record?.timeRecords.count == 2)
                #expect(record?.timeRecords[0] == source.timeRecords[0])
                #expect(record?.timeRecords[1] == source.timeRecords[1])
                #expect(record?.timeWorked == source.timeRecords[0].timeWorked + source.timeRecords[1].timeWorked)
                
                #expect(record?.uptimeRecords.count == 2)
                #expect(record?.uptimeRecords[0] == source.uptimeRecords[0])
                #expect(record?.uptimeRecords[1] == source.uptimeRecords[1])
                #expect(record?.systemUptime == source.uptimeRecords[0].uptime + source.uptimeRecords[1].uptime)
            case 5:
                #expect(record?.timeRecords.count == 1)
                #expect(record?.timeRecords[0] == source.timeRecords[2])
                #expect(record?.timeWorked == source.timeRecords[2].timeWorked)
                
                #expect(record?.uptimeRecords.count == 1)
                #expect(record?.uptimeRecords[0] == source.uptimeRecords[2])
                #expect(record?.systemUptime == source.uptimeRecords[2].uptime)
            default:
                #expect(record?.timeRecords.count == 0)
                #expect(record?.timeWorked == 0)
                
                #expect(record?.uptimeRecords.count == 0)
                #expect(record?.systemUptime == 0)
            }
        }
        
        NotificationCenter.default.post(name: ModelContext.didSave, object: nil)
        
        let records2 = await iterator.next()
        #expect(records?.count == records2?.count)
        
        for i in 0..<31 {
            #expect(records?[i].timeRecords == records2?[i].timeRecords)
            #expect(records?[i].uptimeRecords == records2?[i].uptimeRecords)
        }
    }
    
    @Test func testUpdateRecord() async throws {
        let source = FakeLocalDataSource()
        source.initForUpdate()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let record = CalendarRecord(
            date: formatter.date(from: "2025-12-01 00:00:00") ?? .now,
            timeRecords: [
                source.timeRecords[1],
                TimeRecord(
                    id: source.timeRecords[2].id,
                    checkIn: formatter.date(from: "2025-12-01 12:00:00"),
                    checkOut: formatter.date(from: "2025-12-01 13:00:00"),
                    breakTimes: source.timeRecords[2].breakTimes
                ),
                TimeRecord(
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
            uptimeRecords: [
                source.uptimeRecords[1],
                SystemUptimeRecord(
                    id: source.uptimeRecords[2].id,
                    launch: formatter.date(from: "2025-12-01 12:00:00") ?? .now,
                    shutdown: formatter.date(from: "2025-12-01 13:00:00") ?? .now,
                    sleepRecords: source.uptimeRecords[2].sleepRecords
                ),
                SystemUptimeRecord(
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
        
        let repository = DefaultCalendarRecordRepository(source)
        try repository.updateRecord(record)
        
        #expect(source.timeInserted.count == 1)
        #expect(source.timeInserted[0] == record.timeRecords[2])
        #expect(source.timeUpdated.count == 1)
        #expect(source.timeUpdated[0] == record.timeRecords[1])
        #expect(source.timeDeleted.count == 1)
        #expect(source.timeDeleted[0] == source.timeRecords[0])
        
        #expect(source.uptimeInserted.count == 1)
        #expect(source.uptimeInserted[0] == record.uptimeRecords[2])
        #expect(source.uptimeUpdated.count == 1)
        #expect(source.uptimeUpdated[0] == record.uptimeRecords[1])
        #expect(source.uptimeDeleted.count == 1)
        #expect(source.uptimeDeleted[0] == source.uptimeRecords[0])
    }
    
    class FakeLocalDataSource: LocalDataSource {
        var timeRecords: [TimeRecord] = []
        var uptimeRecords: [SystemUptimeRecord] = []
        
        func initForGet() {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            timeRecords = [
                TimeRecord(
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
                    checkIn: formatter.date(from: "2025-12-05 08:30:00"),
                    checkOut: formatter.date(from: "2025-12-05 17:30:00"),
                    breakTimes: []
                )
            ]
            
            uptimeRecords = [
                SystemUptimeRecord(
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
                    launch: formatter.date(from: "2025-12-05 08:00:00") ?? .now,
                    shutdown: formatter.date(from: "2025-12-05 18:00:00") ?? .now,
                    sleepRecords: []
                )
            ]
        }
        
        func initForUpdate() {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let date = formatter.date(from: "2025-12-01 00:00:00") ?? .now
            
            for _ in 1...3 {
                timeRecords.append(
                    TimeRecord(
                        checkIn: date,
                        checkOut: date,
                        breakTimes: [
                            TimeRecord.BreakTime(
                                start: date,
                                end: date
                            )
                        ]
                    )
                )
                
                uptimeRecords.append(
                    SystemUptimeRecord(
                        launch: date,
                        shutdown: date,
                        sleepRecords: [
                            SystemUptimeRecord.SleepRecord(
                                start: date,
                                end: date
                            )
                        ]
                    )
                )
            }
        }
        
        func getTimeRecord(id: UUID) throws -> TimeRecord? { nil }
        func getBreakTime(id: UUID) throws -> TimeRecord.BreakTime? { nil }
        
        func getTimeRecords(year: Int, month: Int) throws -> [TimeRecord] {
            timeRecords
        }
        
        var timeInserted: [TimeRecord] = []
        func insertTimeRecord(_ record: TimeRecord) throws {
            timeInserted.append(record)
        }
        
        var timeUpdated: [TimeRecord] = []
        func updateTimeRecord(_ record: TimeRecord) throws {
            timeUpdated.append(record)
        }
        
        var timeDeleted: [TimeRecord] = []
        func deleteTimeRecord(_ record: TimeRecord) throws {
            timeDeleted.append(record)
        }
        
        func getUptimeRecords(year: Int, month: Int) throws -> [SystemUptimeRecord] {
            uptimeRecords
        }
        
        var uptimeInserted: [SystemUptimeRecord] = []
        func insertUptimeRecord(_ record: SystemUptimeRecord) throws {
            uptimeInserted.append(record)
        }
        
        var uptimeUpdated: [SystemUptimeRecord] = []
        func updateUptimeRecord(_ record: SystemUptimeRecord) throws {
            uptimeUpdated.append(record)
        }
        
        var uptimeDeleted: [SystemUptimeRecord] = []
        func deleteUptimeRecord(_ record: SystemUptimeRecord) throws {
            uptimeDeleted.append(record)
        }
    }
}
