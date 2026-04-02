//
//  CalendarViewModelTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2026/03/09.
//

import Foundation
import Testing

@testable import TimeCard

struct CalendarViewModelTests {

    @Test func testFetchRecords() async throws {
        let repository = FakeCalendarRecordRepository()
        let viewModel = CalendarViewModel(repository)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        var records = [
            CalendarRecord(
                date: .now,
                timeRecords: [
                    TimeRecord(
                        checkIn: formatter.date(from: "2026-03-09 08:00:00"),
                        checkOut: formatter.date(from: "2026-03-09 17:00:00")
                    )
                ],
                uptimeRecords: [
                    SystemUptimeRecord(
                        launch: formatter.date(from: "2026-03-09 07:00:00") ?? .now,
                        shutdown: formatter.date(from: "2026-03-09 18:00:00") ?? .now
                    )
                ]
            )
        ]
        repository.publish?(records)
        
        try await Task.sleep(for: .milliseconds(1))
        
        #expect(viewModel.records.count == records.count)
        #expect(viewModel.records[0].date == records[0].date)
        #expect(viewModel.records[0].timeRecords.count == records[0].timeRecords.count)
        #expect(viewModel.records[0].timeRecords[0].checkIn == records[0].timeRecords[0].checkIn)
        #expect(viewModel.records[0].timeRecords[0].checkOut == records[0].timeRecords[0].checkOut)
        #expect(viewModel.records[0].timeRecords[0].breakTimes.count == records[0].timeRecords[0].breakTimes.count)
        #expect(viewModel.records[0].timeRecords[0].timeWorked == records[0].timeRecords[0].timeWorked)
        #expect(viewModel.records[0].timeWorked == records[0].timeWorked)
        #expect(viewModel.records[0].systemUptime == records[0].systemUptime)
        #expect(viewModel.timeWorkedSum == records.timeWorkedSum)
        #expect(viewModel.systemUptimeSum == records.systemUptimeSum)
        
        records = [
            CalendarRecord(
                date: .now,
                timeRecords: [
                    TimeRecord(
                        checkIn: formatter.date(from: "2026-03-09 08:00:00"),
                        checkOut: formatter.date(from: "2026-03-10 02:00:00"),
                        breakTimes: [
                            TimeRecord.BreakTime(
                                start: formatter.date(from: "2026-03-09 23:00:00"),
                                end: formatter.date(from: "2026-03-10 01:00:00")
                            )
                        ]
                    )
                ],
                uptimeRecords: [
                    SystemUptimeRecord(
                        launch: formatter.date(from: "2026-03-09 07:00:00") ?? .now,
                        shutdown: formatter.date(from: "2026-03-09 18:00:00") ?? .now,
                        sleepRecords: [
                            SystemUptimeRecord.SleepRecord(
                                start: formatter.date(from: "2026-03-09 23:00:00") ?? .now,
                                end: formatter.date(from: "2026-03-10 01:00:00") ?? .now
                            )
                        ]
                    )
                ]
            )
        ]
        repository.publish?(records)
        
        try await Task.sleep(for: .milliseconds(1))
        
        #expect(viewModel.records.count == records.count)
        #expect(viewModel.records[0].date == records[0].date)
        #expect(viewModel.records[0].timeRecords.count == records[0].timeRecords.count)
        #expect(viewModel.records[0].timeRecords[0].checkIn == records[0].timeRecords[0].checkIn)
        #expect(viewModel.records[0].timeRecords[0].checkOut == records[0].timeRecords[0].checkOut)
        #expect(viewModel.records[0].timeRecords[0].breakTimes.count == records[0].timeRecords[0].breakTimes.count)
        #expect(viewModel.records[0].timeRecords[0].breakTimes[0].start == records[0].timeRecords[0].breakTimes[0].start)
        #expect(viewModel.records[0].timeRecords[0].breakTimes[0].end == records[0].timeRecords[0].breakTimes[0].end)
        #expect(viewModel.records[0].timeRecords[0].timeWorked == records[0].timeRecords[0].timeWorked)
        #expect(viewModel.records[0].timeWorked == records[0].timeWorked)
        #expect(viewModel.records[0].systemUptime == records[0].systemUptime)
        #expect(viewModel.timeWorkedSum == records.timeWorkedSum)
        #expect(viewModel.systemUptimeSum == records.systemUptimeSum)
    }
    
    @Test func testEditable() async throws {
        // future is not editable
        var record = CalendarViewModel.CalendarRecord(date: Date(timeIntervalSinceNow: 24 * 60 * 60))
        #expect(record.editable == false)
        
        // past is editable
        record = CalendarViewModel.CalendarRecord(date: Date(timeIntervalSinceNow: -24 * 60 * 60))
        #expect(record.editable == true)
        
        // time record is empty
        record = CalendarViewModel.CalendarRecord(date: .now)
        #expect(record.editable == true)
        
        // not check in
        record = CalendarViewModel.CalendarRecord(date: .now, timeRecords: [
            CalendarViewModel.TimeRecord()
        ])
        #expect(record.editable == true)
        
        // not check out
        record = CalendarViewModel.CalendarRecord(date: .now, timeRecords: [
            CalendarViewModel.TimeRecord(checkIn: .now)
        ])
        #expect(record.editable == true)
        
        // fixed
        record = CalendarViewModel.CalendarRecord(date: .now, timeRecords: [
            CalendarViewModel.TimeRecord(checkIn: .now, checkOut: .now)
        ])
        #expect(record.editable == true)
        
        // multipul time record
        record = CalendarViewModel.CalendarRecord(date: .now, timeRecords: [
            CalendarViewModel.TimeRecord(checkIn: .now, checkOut: .now),
            CalendarViewModel.TimeRecord(checkIn: .now)
        ])
        #expect(record.editable == true)
        
        // multipul time record, fixed
        record = CalendarViewModel.CalendarRecord(date: .now, timeRecords: [
            CalendarViewModel.TimeRecord(checkIn: .now, checkOut: .now),
            CalendarViewModel.TimeRecord(checkIn: .now, checkOut: .now)
        ])
        #expect(record.editable == true)
    }

    @Test func testInterval() async throws {
        let date1 = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 9, hour: 8))
        let date2 = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 9, hour: 17))
        let date3 = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 2))
        var record = CalendarViewModel.TimeRecord(checkIn: date1, checkOut: date2)
        #expect(record.interval.formatted(.timeWorked) == "17:00")
        
        var breakTime = CalendarViewModel.BreakTime(start: date1, end: date2)
        #expect(breakTime.interval.formatted(.timeWorked) == "17:00")
        
        record = CalendarViewModel.TimeRecord(checkIn: date1, checkOut: date3)
        #expect(record.interval.formatted(.timeWorked) == "26:00")
        
        breakTime = CalendarViewModel.BreakTime(start: date1, end: date3)
        #expect(breakTime.interval.formatted(.timeWorked) == "26:00")
    }
    
    class FakeCalendarRecordRepository: CalendarRecordRepository {
        var publish: (([CalendarRecord]) -> Void)?
        func getRecordsStream(year: Int, month: Int) -> AsyncStream<[TimeCard.CalendarRecord]> {
            AsyncStream { continuation in
                publish = { records in
                    continuation.yield(records)
                }
            }
        }
        
        func getRecord(year: Int, month: Int, day: Int) throws -> TimeCard.CalendarRecord {
            CalendarRecord(date: .now, timeRecords: [], uptimeRecords: [])
        }
        func updateRecord(_ record: TimeCard.CalendarRecord) throws {}
    }
}
