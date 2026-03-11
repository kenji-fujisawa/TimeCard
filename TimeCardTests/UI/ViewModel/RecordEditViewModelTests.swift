//
//  RecordEditViewModelTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2026/03/10.
//

import Foundation
import Testing

@testable import TimeCard

struct RecordEditViewModelTests {

    @Test func testIsValidTimeRecord_order() async throws {
        let viewModel = TimeRecordEditViewModel(date: .now)
        
        // reversed checkIn and checkOut
        let record = TimeRecordEditViewModel.TimeRecord(
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
        let record1 = TimeRecordEditViewModel.TimeRecord(
            checkIn: Date(timeIntervalSinceNow: 60),
            checkOut: Date(timeIntervalSinceNow: 120)
        )
        let record2 = TimeRecordEditViewModel.TimeRecord(
            checkIn: Date(timeIntervalSinceNow: 180),
            checkOut: Date(timeIntervalSinceNow: 240)
        )
        let record3 = TimeRecordEditViewModel.TimeRecord(
            checkIn: Date(timeIntervalSinceNow: 90),
            checkOut: Date(timeIntervalSinceNow: 210)
        )
        
        let viewModel = TimeRecordEditViewModel(date: .now)
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
        let timeRecord = TimeRecordEditViewModel.TimeRecord(
            checkIn: .now,
            checkOut: Date(timeIntervalSinceNow: 180)
        )
        
        // reversed start and end
        let breakTime = TimeRecordEditViewModel.BreakTime(
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
        let breakTime1 = TimeRecordEditViewModel.BreakTime(
            start: Date(timeIntervalSinceNow: 60),
            end: Date(timeIntervalSinceNow: 120)
        )
        let breakTime2 = TimeRecordEditViewModel.BreakTime(
            start: Date(timeIntervalSinceNow: 180),
            end: Date(timeIntervalSinceNow: 240)
        )
        let breakTime3 = TimeRecordEditViewModel.BreakTime(
            start: Date(timeIntervalSinceNow: 90),
            end: Date(timeIntervalSinceNow: 210)
        )
        
        let timeRecord = TimeRecordEditViewModel.TimeRecord(
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
    
    @Test func testIsValidTimeRecordEditViewModel() async throws {
        let viewModel = TimeRecordEditViewModel(date: .now)
        #expect(viewModel.isValid() == true)
        
        // reversed TimeRecord
        let record1 = TimeRecordEditViewModel.TimeRecord(
            checkIn: Date(timeIntervalSinceNow: 180),
            checkOut: Date(timeIntervalSinceNow: 120)
        )
        viewModel.records.append(record1)
        #expect(viewModel.isValid() == false)
        
        // ok
        record1.checkIn = Date(timeIntervalSinceNow: 60)
        #expect(viewModel.isValid() == true)
        
        // overlap TimeRecord
        let record2 = TimeRecordEditViewModel.TimeRecord(
            checkIn: Date(timeIntervalSinceNow: 90),
            checkOut: Date(timeIntervalSinceNow: 240)
        )
        viewModel.records.append(record2)
        #expect(viewModel.isValid() == false)
        
        // ok
        record2.checkIn = Date(timeIntervalSinceNow: 180)
        #expect(viewModel.isValid() == true)
        
        // reversed BreakTime
        let breakTime1 = TimeRecordEditViewModel.BreakTime(
            start: Date(timeIntervalSinceNow: 100),
            end: Date(timeIntervalSinceNow: 90)
        )
        record1.breakTimes.append(breakTime1)
        #expect(viewModel.isValid() == false)
        
        // ok
        breakTime1.start = Date(timeIntervalSinceNow: 70)
        #expect(viewModel.isValid() == true)
        
        // overlap BreakTime
        let breakTime2 = TimeRecordEditViewModel.BreakTime(
            start: Date(timeIntervalSinceNow: 80),
            end: Date(timeIntervalSinceNow: 100)
        )
        record1.breakTimes.append(breakTime2)
        #expect(viewModel.isValid() == false)
    }
    
    @Test func testIsValidUptimeRecord_order() async throws {
        let viewModel = UptimeRecordEditViewModel(date: .now)
        
        // reversed launch and shutdown
        let record = UptimeRecordEditViewModel.SystemUptimeRecord(
            launch: Date(timeIntervalSinceNow: 120),
            shutdown: Date(timeIntervalSinceNow: 60)
        )
        #expect(viewModel.isValid(record) == false)
        
        // ok
        record.launch = Date(timeIntervalSinceNow: 30)
        #expect(viewModel.isValid(record) == true)
        
        // before minimum date
        record.launch = Date(timeIntervalSinceNow: -60)
        #expect(viewModel.isValid(record) == false)
    }
    
    @Test func testIsValidUptimeRecord_overlap() async throws {
        let record1 = UptimeRecordEditViewModel.SystemUptimeRecord(
            launch: Date(timeIntervalSinceNow: 60),
            shutdown: Date(timeIntervalSinceNow: 120)
        )
        let record2 = UptimeRecordEditViewModel.SystemUptimeRecord(
            launch: Date(timeIntervalSinceNow: 180),
            shutdown: Date(timeIntervalSinceNow: 240)
        )
        let record3 = UptimeRecordEditViewModel.SystemUptimeRecord(
            launch: Date(timeIntervalSinceNow: 90),
            shutdown: Date(timeIntervalSinceNow: 210)
        )
        
        let viewModel = UptimeRecordEditViewModel(date: .now)
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
        record3.shutdown = Date(timeIntervalSinceNow: 120)
        #expect(viewModel.isValid(record1) == false)
        #expect(viewModel.isValid(record2) == true)
        #expect(viewModel.isValid(record3) == false)
        
        // overlap 2 and 3
        record3.launch = Date(timeIntervalSinceNow: 180)
        record3.shutdown = Date(timeIntervalSinceNow: 210)
        #expect(viewModel.isValid(record1) == true)
        #expect(viewModel.isValid(record2) == false)
        #expect(viewModel.isValid(record3) == false)
    }
    
    @Test func testIsValidSleepRecord_order() async throws {
        let uptimeRecord = UptimeRecordEditViewModel.SystemUptimeRecord(
            launch: .now,
            shutdown: Date(timeIntervalSinceNow: 180)
        )
        
        // reversed start and end
        let sleep = UptimeRecordEditViewModel.SleepRecord(
            start: Date(timeIntervalSinceNow: 120),
            end: Date(timeIntervalSinceNow: 60)
        )
        #expect(uptimeRecord.isValid(sleep) == false)
        
        // ok
        sleep.start = Date(timeIntervalSinceNow: 30)
        #expect(uptimeRecord.isValid(sleep) == true)
        
        // before launch
        sleep.start = Date(timeIntervalSinceNow: -60)
        #expect(uptimeRecord.isValid(sleep) == false)
        
        // after shutdown
        sleep.start = Date(timeIntervalSinceNow: 30)
        sleep.end = Date(timeIntervalSinceNow: 210)
        #expect(uptimeRecord.isValid(sleep) == false)
    }
    
    @Test func testIsValidSleepRecord_overlap() async throws {
        let sleep1 = UptimeRecordEditViewModel.SleepRecord(
            start: Date(timeIntervalSinceNow: 60),
            end: Date(timeIntervalSinceNow: 120)
        )
        let sleep2 = UptimeRecordEditViewModel.SleepRecord(
            start: Date(timeIntervalSinceNow: 180),
            end: Date(timeIntervalSinceNow: 240)
        )
        let sleep3 = UptimeRecordEditViewModel.SleepRecord(
            start: Date(timeIntervalSinceNow: 90),
            end: Date(timeIntervalSinceNow: 210)
        )
        
        let uptimeRecord = UptimeRecordEditViewModel.SystemUptimeRecord(
            launch: Date(timeIntervalSinceNow: 0),
            shutdown: Date(timeIntervalSinceNow: 300)
        )
        uptimeRecord.sleepRecords.append(sleep1)
        uptimeRecord.sleepRecords.append(sleep2)
        
        // ok
        #expect(uptimeRecord.isValid(sleep1) == true)
        #expect(uptimeRecord.isValid(sleep2) == true)
        
        // overlap all
        uptimeRecord.sleepRecords.append(sleep3)
        #expect(uptimeRecord.isValid(sleep1) == false)
        #expect(uptimeRecord.isValid(sleep2) == false)
        #expect(uptimeRecord.isValid(sleep3) == false)
        
        // overlap 1 and 3
        sleep3.end = Date(timeIntervalSinceNow: 120)
        #expect(uptimeRecord.isValid(sleep1) == false)
        #expect(uptimeRecord.isValid(sleep2) == true)
        #expect(uptimeRecord.isValid(sleep3) == false)
        
        // overlap 2 and 3
        sleep3.start = Date(timeIntervalSinceNow: 180)
        sleep3.end = Date(timeIntervalSinceNow: 210)
        #expect(uptimeRecord.isValid(sleep1) == true)
        #expect(uptimeRecord.isValid(sleep2) == false)
        #expect(uptimeRecord.isValid(sleep3) == false)
    }
    
    @Test func testIsValidUptimeRecordEditViewModel() async throws {
        let viewModel = UptimeRecordEditViewModel(date: .now)
        #expect(viewModel.isValid() == true)
        
        // reversed UptimeRecord
        let record1 = UptimeRecordEditViewModel.SystemUptimeRecord(
            launch: Date(timeIntervalSinceNow: 180),
            shutdown: Date(timeIntervalSinceNow: 120)
        )
        viewModel.records.append(record1)
        #expect(viewModel.isValid() == false)
        
        // ok
        record1.launch = Date(timeIntervalSinceNow: 60)
        #expect(viewModel.isValid() == true)
        
        // overlap UptimeRecord
        let record2 = UptimeRecordEditViewModel.SystemUptimeRecord(
            launch: Date(timeIntervalSinceNow: 90),
            shutdown: Date(timeIntervalSinceNow: 240)
        )
        viewModel.records.append(record2)
        #expect(viewModel.isValid() == false)
        
        // ok
        record2.launch = Date(timeIntervalSinceNow: 180)
        #expect(viewModel.isValid() == true)
        
        // reversed SleepRecord
        let sleep1 = UptimeRecordEditViewModel.SleepRecord(
            start: Date(timeIntervalSinceNow: 100),
            end: Date(timeIntervalSinceNow: 90)
        )
        record1.sleepRecords.append(sleep1)
        #expect(viewModel.isValid() == false)
        
        // ok
        sleep1.start = Date(timeIntervalSinceNow: 70)
        #expect(viewModel.isValid() == true)
        
        // overlap SleepRecord
        let sleep2 = UptimeRecordEditViewModel.SleepRecord(
            start: Date(timeIntervalSinceNow: 80),
            end: Date(timeIntervalSinceNow: 100)
        )
        record1.sleepRecords.append(sleep2)
        #expect(viewModel.isValid() == false)
    }
    
    @Test func testIsValidRecordEditViewModel() async throws {
        let repository = FakeCalendarRecordRepository()
        let viewModel = RecordEditViewModel(repository, .now)
        #expect(viewModel.isValid() == true)
        
        // invalid TimeRecord
        let timeRecord = TimeRecordEditViewModel.TimeRecord(
            checkIn: Date(timeIntervalSinceNow: 180),
            checkOut: Date(timeIntervalSinceNow: 120)
        )
        viewModel.timeViewModel.records.append(timeRecord)
        #expect(viewModel.isValid() == false)
        
        // ok
        timeRecord.checkIn = Date(timeIntervalSinceNow: 60)
        #expect(viewModel.isValid() == true)
        
        // invalid UptimeRecord
        let uptimeRecord = UptimeRecordEditViewModel.SystemUptimeRecord(
            launch: Date(timeIntervalSinceNow: 180),
            shutdown: Date(timeIntervalSinceNow: 120)
        )
        viewModel.uptimeViewModel.records.append(uptimeRecord)
        #expect(viewModel.isValid() == false)
        
        // ok
        uptimeRecord.launch = Date(timeIntervalSinceNow: 60)
        #expect(viewModel.isValid() == true)
    }
    
    class FakeCalendarRecordRepository: CalendarRecordRepository {
        func getRecordsStream(year: Int, month: Int) -> AsyncStream<[TimeCard.CalendarRecord]> {
            AsyncStream { _ in }
        }
        func getRecord(year: Int, month: Int, day: Int) throws -> TimeCard.CalendarRecord {
            CalendarRecord(date: .now, timeRecords: [], uptimeRecords: [])
        }
        func updateRecord(_ record: TimeCard.CalendarRecord) throws {}
    }
}
