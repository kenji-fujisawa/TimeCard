//
//  CalendarViewModelTests.swift
//  TimeCardClientIOSTests
//
//  Created by uhimania on 2026/03/16.
//

import Foundation
import Testing

@testable import TimeCardClientIOS

struct CalendarViewModelTests {

    @Test func testFetchRecords() async throws {
        let repository = FakeCalendarRecordRepository()
        let viewModel = CalendarViewModel(repository)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        var records = [
            CalendarRecord(
                date: .now,
                records: [
                    TimeRecord(
                        id: UUID(),
                        checkIn: formatter.date(from: "2026-03-09 08:00:00"),
                        checkOut: formatter.date(from: "2026-03-09 17:00:00"),
                        breakTimes: []
                    )
                ]
            )
        ]
        repository.publish?(records)
        
        try await Task.sleep(for: .milliseconds(1))
        
        #expect(viewModel.records.count == records.count)
        #expect(viewModel.records[0].date == records[0].date)
        #expect(viewModel.records[0].records.count == records[0].records.count)
        #expect(viewModel.records[0].records[0].checkIn == records[0].records[0].checkIn)
        #expect(viewModel.records[0].records[0].checkOut == records[0].records[0].checkOut)
        #expect(viewModel.records[0].records[0].breakTimes.count == records[0].records[0].breakTimes.count)
        
        records = [
            CalendarRecord(
                date: .now,
                records: [
                    TimeRecord(
                        id: UUID(),
                        checkIn: formatter.date(from: "2026-03-09 08:00:00"),
                        checkOut: formatter.date(from: "2026-03-10 02:00:00"),
                        breakTimes: [
                            TimeRecord.BreakTime(
                                id: UUID(),
                                start: formatter.date(from: "2026-03-09 23:00:00"),
                                end: formatter.date(from: "2026-03-10 01:00:00")
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
        #expect(viewModel.records[0].records.count == records[0].records.count)
        #expect(viewModel.records[0].records[0].checkIn == records[0].records[0].checkIn)
        #expect(viewModel.records[0].records[0].checkOut == records[0].records[0].checkOut)
        #expect(viewModel.records[0].records[0].breakTimes.count == records[0].records[0].breakTimes.count)
        #expect(viewModel.records[0].records[0].breakTimes[0].start == records[0].records[0].breakTimes[0].start)
        #expect(viewModel.records[0].records[0].breakTimes[0].end == records[0].records[0].breakTimes[0].end)
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
        var publish: (([CalendarRecord]) -> Void)? = nil
        func getRecordsStream(year: Int, month: Int) -> AsyncThrowingStream<[TimeCardClientIOS.CalendarRecord], any Error> {
            AsyncThrowingStream { continuation in
                publish = { records in
                    continuation.yield(records)
                }
            }
        }
        
        func getRecord(year: Int, month: Int, day: Int) throws -> TimeCardClientIOS.CalendarRecord {
            CalendarRecord(date: .now, records: [])
        }
        func updateRecord(_ record: TimeCardClientIOS.CalendarRecord) async throws {}
    }
}
