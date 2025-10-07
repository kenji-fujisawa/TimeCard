//
//  TimeRecordTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2025/10/06.
//

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

}
