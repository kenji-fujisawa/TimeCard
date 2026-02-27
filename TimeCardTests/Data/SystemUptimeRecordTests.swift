//
//  SystemUptimeRecordTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2025/11/13.
//

import Foundation
import Testing

@testable import TimeCard

struct SystemUptimeRecordTests {
    
    @Test func testUptimes() async throws {
        let launch1 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 9, minute: 0, second: 0))
        let shutdown1 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 18, minute: 0, second: 0))
        let sleepStart1_1 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 12, minute: 0, second: 0))
        let sleepEnd1_1 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 13, minute: 0, second: 0))
        let sleepStart1_2 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 15, minute: 0, second: 0))
        let sleepEnd1_2 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 15, minute: 30, second: 0))
        let sleepStart1_3 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 17, minute: 0, second: 0))
        let sleepEnd1_3 = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 7, hour: 17, minute: 0, second: 30))
        
        var record = SystemUptimeRecord(year: 2025, month: 11, day: 13, launch: launch1!, shutdown: shutdown1!)
        let hour9: TimeInterval = 9 * 60 * 60
        #expect(record.uptimes == hour9)
        
        let sleep1 = SystemUptimeRecord.SleepRecord(start: sleepStart1_1!, end: sleepEnd1_1!)
        record.sleepRecords.append(sleep1)
        let hour8: TimeInterval = 8 * 60 * 60
        #expect(record.uptimes == hour8)
        
        let sleep2 = SystemUptimeRecord.SleepRecord(start: sleepStart1_2!, end: sleepEnd1_2!)
        record.sleepRecords.append(sleep2)
        let hour7_5: TimeInterval = hour8 - 30 * 60
        #expect(record.uptimes == hour7_5)
        
        let sleep3 = SystemUptimeRecord.SleepRecord(start: sleepStart1_3!, end: sleepEnd1_3!)
        record.sleepRecords.append(sleep3)
        #expect(record.uptimes == hour7_5 - 30)
    }
}
