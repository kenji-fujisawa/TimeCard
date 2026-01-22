//
//  CalendarViewTests.swift
//  TimeCardUITests
//
//  Created by uhimania on 2026/01/20.
//

import XCTest

final class CalendarViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testRefreshRecords() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "CalendarViewTests"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.buttons["button_check_in"].waitForExistence(timeout: 3))
        app.buttons["button_check_in"].tap()
        
        XCTAssertTrue(app.staticTexts["text_check_in"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["text_check_in"].value as! String, Date.now.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute()))
        
        XCTAssertTrue(app.buttons["button_check_out"].waitForExistence(timeout: 3))
        app.buttons["button_check_out"].tap()
        
        XCTAssertTrue(app.staticTexts["text_check_out"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["text_check_out"].value as! String, Date.now.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute()))
    }
    
    func testEditButton() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "CalendarViewTests"]
        app.launch()
        app.activate()
        
        let day = Calendar.current.component(.day, from: .now)
        
        XCTAssertEqual(app.buttons.matching(identifier: "button_edit").count, day - 1)
        
        XCTAssertTrue(app.buttons["button_check_in"].waitForExistence(timeout: 3))
        app.buttons["button_check_in"].tap()
        
        XCTAssertTrue(app.buttons["button_check_out"].waitForExistence(timeout: 3))
        app.buttons["button_check_out"].tap()
        
        XCTAssertEqual(app.buttons.matching(identifier: "button_edit").count, day)
    }
}
