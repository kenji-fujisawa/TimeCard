//
//  CalendarDetailViewModelTests.swift
//  TimeCardClientIOSTests
//
//  Created by uhimania on 2026/03/16.
//

import Foundation
import Testing

@testable import TimeCardClientIOS

struct CalendarDetailViewModelTests {

    @Test func testIsValidTimeRecord_order() async throws {
        let repository = FakeCalendarRecordRepository()
        let viewModel = CalendarDetailViewModel(repository, .now)
        
        // reversed checkIn and checkOut
        let record = CalendarDetailViewModel.TimeRecord(
            checkIn: Date(timeIntervalSinceNow: 120),
            checkOut: Date(timeIntervalSinceNow: 60)
        )
        #expect(viewModel.isValid(record) == false)
        
        // ok
        record.checkIn = Date(timeIntervalSinceNow: 30)
        #expect(viewModel.isValid(record) == true)
        
        // before minimum date
        record.checkIn = Date(timeIntervalSinceNow: -60)
        #expect(viewModel.isValid(record) == false)
    }
    
    @Test func testIsValidTimeRecord_overlap() async throws {
        let record1 = CalendarDetailViewModel.TimeRecord(
            checkIn: Date(timeIntervalSinceNow: 60),
            checkOut: Date(timeIntervalSinceNow: 120)
        )
        let record2 = CalendarDetailViewModel.TimeRecord(
            checkIn: Date(timeIntervalSinceNow: 180),
            checkOut: Date(timeIntervalSinceNow: 240)
        )
        let record3 = CalendarDetailViewModel.TimeRecord(
            checkIn: Date(timeIntervalSinceNow: 90),
            checkOut: Date(timeIntervalSinceNow: 210)
        )
        
        let repository = FakeCalendarRecordRepository()
        let viewModel = CalendarDetailViewModel(repository, .now)
        viewModel.records.append(record1)
        viewModel.records.append(record2)
        
        // ok
        #expect(viewModel.isValid(record1) == true)
        #expect(viewModel.isValid(record2) == true)
        
        // overlap all
        viewModel.records.append(record3)
        #expect(viewModel.isValid(record1) == false)
        #expect(viewModel.isValid(record2) == false)
        #expect(viewModel.isValid(record3) == false)
        
        // overlap 1 and 3
        record3.checkOut = Date(timeIntervalSinceNow: 120)
        #expect(viewModel.isValid(record1) == false)
        #expect(viewModel.isValid(record2) == true)
        #expect(viewModel.isValid(record3) == false)
        
        // overlap 2 and 3
        record3.checkIn = Date(timeIntervalSinceNow: 180)
        record3.checkOut = Date(timeIntervalSinceNow: 210)
        #expect(viewModel.isValid(record1) == true)
        #expect(viewModel.isValid(record2) == false)
        #expect(viewModel.isValid(record3) == false)
    }
    
    @Test func testIsValidBreakTime_order() async throws {
        let timeRecord = CalendarDetailViewModel.TimeRecord(
            checkIn: .now,
            checkOut: Date(timeIntervalSinceNow: 180)
        )
        
        // reversed start and end
        let breakTime = CalendarDetailViewModel.BreakTime(
            start: Date(timeIntervalSinceNow: 120),
            end: Date(timeIntervalSinceNow: 60)
        )
        #expect(timeRecord.isValid(breakTime) == false)
        
        // ok
        breakTime.start = Date(timeIntervalSinceNow: 30)
        #expect(timeRecord.isValid(breakTime) == true)
        
        // before checkIn
        breakTime.start = Date(timeIntervalSinceNow: -60)
        #expect(timeRecord.isValid(breakTime) == false)
        
        // after checkOut
        breakTime.start = Date(timeIntervalSinceNow: 30)
        breakTime.end = Date(timeIntervalSinceNow: 210)
        #expect(timeRecord.isValid(breakTime) == false)
    }
    
    @Test func testIsValidBreakTime_overlap() async throws {
        let breakTime1 = CalendarDetailViewModel.BreakTime(
            start: Date(timeIntervalSinceNow: 60),
            end: Date(timeIntervalSinceNow: 120)
        )
        let breakTime2 = CalendarDetailViewModel.BreakTime(
            start: Date(timeIntervalSinceNow: 180),
            end: Date(timeIntervalSinceNow: 240)
        )
        let breakTime3 = CalendarDetailViewModel.BreakTime(
            start: Date(timeIntervalSinceNow: 90),
            end: Date(timeIntervalSinceNow: 210)
        )
        
        let timeRecord = CalendarDetailViewModel.TimeRecord(
            checkIn: Date(timeIntervalSinceNow: 0),
            checkOut: Date(timeIntervalSinceNow: 300)
        )
        timeRecord.breakTimes.append(breakTime1)
        timeRecord.breakTimes.append(breakTime2)
        
        // ok
        #expect(timeRecord.isValid(breakTime1) == true)
        #expect(timeRecord.isValid(breakTime2) == true)
        
        // overlap all
        timeRecord.breakTimes.append(breakTime3)
        #expect(timeRecord.isValid(breakTime1) == false)
        #expect(timeRecord.isValid(breakTime2) == false)
        #expect(timeRecord.isValid(breakTime3) == false)
        
        // overlap 1 and 3
        breakTime3.end = Date(timeIntervalSinceNow: 120)
        #expect(timeRecord.isValid(breakTime1) == false)
        #expect(timeRecord.isValid(breakTime2) == true)
        #expect(timeRecord.isValid(breakTime3) == false)
        
        // overlap 2 and 3
        breakTime3.start = Date(timeIntervalSinceNow: 180)
        breakTime3.end = Date(timeIntervalSinceNow: 210)
        #expect(timeRecord.isValid(breakTime1) == true)
        #expect(timeRecord.isValid(breakTime2) == false)
        #expect(timeRecord.isValid(breakTime3) == false)
    }
    
    @Test func testIsValidCalendarDetailViewModel() async throws {
        let repository = FakeCalendarRecordRepository()
        let viewModel = CalendarDetailViewModel(repository, .now)
        
        // not changed
        #expect(viewModel.isValid() == false)
        
        // ok
        let record1 = CalendarDetailViewModel.TimeRecord(
            checkIn: Date(timeIntervalSinceNow: 0),
            checkOut: Date(timeIntervalSinceNow: 30)
        )
        viewModel.records.append(record1)
        #expect(viewModel.isValid() == true)
        
        // reversed TimeRecord
        let record2 = CalendarDetailViewModel.TimeRecord(
            checkIn: Date(timeIntervalSinceNow: 180),
            checkOut: Date(timeIntervalSinceNow: 120)
        )
        viewModel.records.append(record2)
        #expect(viewModel.isValid() == false)
        
        // ok
        record2.checkIn = Date(timeIntervalSinceNow: 60)
        #expect(viewModel.isValid() == true)
        
        // overlap TimeRecord
        let record3 = CalendarDetailViewModel.TimeRecord(
            checkIn: Date(timeIntervalSinceNow: 90),
            checkOut: Date(timeIntervalSinceNow: 240)
        )
        viewModel.records.append(record3)
        #expect(viewModel.isValid() == false)
        
        // ok
        record3.checkIn = Date(timeIntervalSinceNow: 180)
        #expect(viewModel.isValid() == true)
        
        // reversed BreakTime
        let breakTime1 = CalendarDetailViewModel.BreakTime(
            start: Date(timeIntervalSinceNow: 100),
            end: Date(timeIntervalSinceNow: 90)
        )
        record2.breakTimes.append(breakTime1)
        #expect(viewModel.isValid() == false)
        
        // ok
        breakTime1.start = Date(timeIntervalSinceNow: 70)
        #expect(viewModel.isValid() == true)
        
        // overlap BreakTime
        let breakTime2 = CalendarDetailViewModel.BreakTime(
            start: Date(timeIntervalSinceNow: 80),
            end: Date(timeIntervalSinceNow: 100)
        )
        record2.breakTimes.append(breakTime2)
        #expect(viewModel.isValid() == false)
    }
    
    class FakeCalendarRecordRepository: CalendarRecordRepository {
        func getRecordsStream(year: Int, month: Int) -> AsyncThrowingStream<[TimeCardClientIOS.CalendarRecord], any Error> {
            AsyncThrowingStream { _ in }
        }
        func getRecord(year: Int, month: Int, day: Int) throws -> TimeCardClientIOS.CalendarRecord {
            CalendarRecord(date: .now, records: [])
        }
        func updateRecord(_ record: TimeCardClientIOS.CalendarRecord) async throws {}
    }
}
