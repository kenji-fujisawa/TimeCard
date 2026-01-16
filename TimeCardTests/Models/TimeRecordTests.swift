//
//  TimeRecordTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2025/10/06.
//

import Foundation
import Testing

@testable import TimeCard

struct TimeRecordTests {

    @Test func testState() async throws {
        let record = TimeRecord(year: 2025, month: 10)
        #expect(record.state == .OffWork)
        
        record.checkIn = .now
        #expect(record.state == .AtWork)
        
        let breakTime = TimeRecord.BreakTime()
        record.breakTimes.append(breakTime)
        #expect(record.state == .AtWork)
        
        breakTime.start = .now
        #expect(record.state == .AtBreak)
        
        breakTime.end = .now
        #expect(record.state == .AtWork)
        
        record.checkOut = .now
        #expect(record.state == .OffWork)
    }
    
    @Test func testTimeWorked() async throws {
        let checkIn = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 9, minute: 0, second: 0))
        let checkOut = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 18, minute: 0, second: 0))
        let breakStart1 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 12, minute: 0, second: 0))
        let breakEnd1 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 13, minute: 0, second: 0))
        let breakStart2 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 15, minute: 0, second: 0))
        let breakEnd2 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 15, minute: 30, second: 0))
        let breakStart3 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 17, minute: 0, second: 0))
        let breakEnd3 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 17, minute: 0, second: 30))
        
        let record = TimeRecord(year: 2025, month: 10)
        #expect(record.timeWorked == 0)
        
        record.checkIn = checkIn
        #expect(record.timeWorked == 0)
        
        record.checkOut = checkOut
        let hour9: TimeInterval = 9 * 60 * 60
        #expect(record.timeWorked == hour9)
        
        let break1 = TimeRecord.BreakTime()
        record.breakTimes.append(break1)
        #expect(record.timeWorked == hour9)
        
        break1.start = breakStart1
        #expect(record.timeWorked == hour9)
        
        break1.end = breakEnd1
        let hour8: TimeInterval = 8 * 60 * 60
        #expect(record.timeWorked == hour8)
        
        let break2 = TimeRecord.BreakTime(start: breakStart2, end: breakEnd2)
        record.breakTimes.append(break2)
        let hour7_5: TimeInterval = hour8 - 30 * 60
        #expect(record.timeWorked == hour7_5)
        
        let break3 = TimeRecord.BreakTime(start: breakStart3, end: breakEnd3)
        record.breakTimes.append(break3)
        #expect(record.timeWorked == hour7_5 - 30)
    }

}
