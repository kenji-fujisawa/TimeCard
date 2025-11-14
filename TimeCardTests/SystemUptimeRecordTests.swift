//
//  SystemUptimeRecordTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2025/11/13.
//

import Testing

@testable import TimeCard

struct SystemUptimeRecordTests {

    @Test func testUptimes() async throws {
        let record = SystemUptimeRecord(year: 2025, month: 11, day: 13, launch: 100, shutdown: 500)
        #expect(record.uptimes == 400)
        
        let sleep1 = SystemUptimeRecord.SleepRecord(start: 200, end: 250)
        record.sleepRecords.append(sleep1)
        #expect(record.uptimes == 350)
        
        let sleep2 = SystemUptimeRecord.SleepRecord(start: 300, end: 400)
        record.sleepRecords.append(sleep2)
        #expect(record.uptimes == 250)
    }

}
