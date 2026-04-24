//
//  FileDataSourceTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2026/04/02.
//

import Testing

@testable import TimeCard

@Suite(.serialized)
struct FileDataSourceTests {

    @Test func testUptimeRecords() async throws {
        let records = [
            SystemUptimeRecord(
                launch: .now,
                shutdown: .now
            ),
            SystemUptimeRecord(
                launch: .now,
                shutdown: .now,
                sleepRecords: [
                    SystemUptimeRecord.SleepRecord(
                        start: .now,
                        end: .now
                    )
                ]
            )
        ]
        
        let source = DefaultFileDataSource()
        var result = try source.getUptimeRecords()
        #expect(result.isEmpty)
        
        try source.saveUptimeRecords(records)
        result = try source.getUptimeRecords()
        #expect(result == records)
        
        try source.removeUptimeRecords()
        result = try source.getUptimeRecords()
        #expect(result.isEmpty)
    }

}
