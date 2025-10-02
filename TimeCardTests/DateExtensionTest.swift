//
//  DateExtensionTest.swift
//  TimeCardTests
//
//  Created by uhimania on 2025/10/02.
//

import Foundation
import Testing

struct DateExtensionTest {

    let date = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 2))
    
    @Test func testYear() async throws {
        #expect(date?.year == 2025)
    }

    @Test func testMonth() async throws {
        #expect(date?.month == 10)
    }
    
    @Test func testDay() async throws {
        #expect(date?.day == 2)
    }
    
    @Test func testWeekDay() async throws {
        #expect(date?.weekDay == "木")
    }
    
    @Test func testIsHoliday() async throws {
        #expect(date?.isHoliday() == false)
        
        let sat = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 4))
        #expect(sat?.isHoliday() == true)
        
        let sun = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 5))
        #expect(sun?.isHoliday() == true)
    }
}
