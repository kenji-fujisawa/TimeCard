//
//  TimeIntervalExtensionTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2025/10/07.
//

import Foundation
import Testing

@testable import TimeCardClientIOS

struct TimeIntervalExtensionTests {

    @Test func testFormatted() async throws {
        var interval: TimeInterval = 30
        #expect(interval.formatted() == "0:00")
        
        interval = 30 * 60
        #expect(interval.formatted() == "0:30")
        
        interval = 8 * 60 * 60
        #expect(interval.formatted() == "8:00")
        
        interval = 32.5 * 60 * 60 + 30
        #expect(interval.formatted() == "32:30")
    }

}
