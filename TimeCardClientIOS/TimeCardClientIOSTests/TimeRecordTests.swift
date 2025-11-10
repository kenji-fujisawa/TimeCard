//
//  TimeRecordTests.swift
//  TimeCardClientIOSTests
//
//  Created by uhimania on 2025/11/07.
//

import Foundation
import Testing

@testable import TimeCardClientIOS

struct TimeRecordTests {

    @Test func testEquatable() async throws {
        let now = Date.now
        let id = UUID()
        let b1 = TimeRecord.BreakTime(id: id, start: now)
        let b2 = TimeRecord.BreakTime(id: id, start: now)
        let b3 = TimeRecord.BreakTime(id: id, start: now, end: now)
        let b4 = TimeRecord.BreakTime(id: id, start: now, end: now)
        #expect(b1 == b2)
        #expect(b1 != b3)
        #expect(b3 == b4)
        
        let t1 = TimeRecord(id: id, year: 2025, month: 11, checkIn: now, breakTimes: [])
        let t2 = TimeRecord(id: id, year: 2025, month: 11, checkIn: now, breakTimes: [])
        let t3 = TimeRecord(id: id, year: 2025, month: 11, checkIn: now, checkOut: now, breakTimes: [b1])
        let t4 = TimeRecord(id: id, year: 2025, month: 11, checkIn: now, checkOut: now, breakTimes: [b2])
        let t5 = TimeRecord(id: id, year: 2025, month: 11, checkIn: now, checkOut: now, breakTimes: [b1, b3])
        let t6 = TimeRecord(id: id, year: 2025, month: 11, checkIn: now, checkOut: now, breakTimes: [b2, b4])
        #expect(t1 == t2)
        #expect(t1 != t3)
        #expect(t3 == t4)
        #expect(t3 != t5)
        #expect(t5 == t6)
        
        var t7 = t6
        let t8: TimeRecord? = t6
        t7.breakTimes[0].start = .distantPast
        #expect(t7 != t8)
        
        t7 = t8!
        #expect(t7 == t8)
    }

}
