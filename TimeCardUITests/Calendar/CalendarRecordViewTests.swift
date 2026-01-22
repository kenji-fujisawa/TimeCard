//
//  CalendarRecordViewTests.swift
//  TimeCardUITests
//
//  Created by uhimania on 2025/12/29.
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
        app.activate()

        XCTAssertTrue(app.staticTexts["text_date"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["text_date"].value as! String, "29(月)")
        
        XCTAssertTrue(app.staticTexts["text_check_in"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["text_check_in"].value as! String, "09:45")
        
        XCTAssertTrue(app.staticTexts["text_check_out"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["text_check_out"].value as! String, "26:12")
        
        XCTAssertTrue(app.staticTexts["text_break_start"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["text_break_start"].value as! String, "23:48")
        
        XCTAssertTrue(app.staticTexts["text_break_end"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["text_break_end"].value as! String, "25:33")
        
        XCTAssertTrue(app.staticTexts["text_time_worked"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["text_time_worked"].value as! String, "14:41")
        
        XCTAssertTrue(app.staticTexts["text_system_uptime"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["text_system_uptime"].value as! String, "14:47")
        
        XCTAssertTrue(app.buttons["button_edit"].waitForExistence(timeout: 3))
        app.buttons["button_edit"].tap()
        
        XCTAssertTrue(app.staticTexts["text_rec_to_edit"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["text_rec_to_edit"].value as! String, "Dec 29")
    }
}
