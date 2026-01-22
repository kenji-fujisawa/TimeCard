//
//  CalendarRecordViewTests.swift
//  TimeCardClientIOSUITests
//
//  Created by uhimania on 2025/12/30.
//

import XCTest

final class CalendarRecordViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testCalendarRecordView() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "CalendarRecordViewTests"]
        app.launch()

        XCTAssertTrue(app.staticTexts["text_date"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["text_date"].label, "29(月)")
        
        XCTAssertTrue(app.staticTexts["text_check_in"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["text_check_in"].label, "09:12")
        
        XCTAssertTrue(app.staticTexts["text_check_out"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["text_check_out"].label, "26:28")
        
        XCTAssertTrue(app.staticTexts["text_break_start"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["text_break_start"].label, "23:45")
        
        XCTAssertTrue(app.staticTexts["text_break_end"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["text_break_end"].label, "25:30")
    }
}
