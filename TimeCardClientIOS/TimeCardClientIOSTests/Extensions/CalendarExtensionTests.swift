//
//  CalendarExtensionTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2025/10/02.
//

import Foundation
import Testing

@testable import TimeCardClientIOS

struct CalendarExtensionTests {

    @Test func testDatesOf() async throws {
        #expect(Calendar.current.datesOf(year: 2025, month: 10).count == 31)
        #expect(Calendar.current.datesOf(year: 2025, month: 2).count == 28)
        #expect(Calendar.current.datesOf(year: 2024, month: 2).count == 29)
        
        let dates = Calendar.current.datesOf(year: 2025, month: 10)
        for i in 0..<31 {
            #expect(dates[i].year == 2025)
            #expect(dates[i].month == 10)
            #expect(dates[i].day == i + 1)
        }
    }

}
