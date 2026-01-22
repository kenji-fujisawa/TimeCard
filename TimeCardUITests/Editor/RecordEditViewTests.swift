//
//  RecordEditViewTests.swift
//  TimeCardUITests
//
//  Created by uhimania on 2026/01/21.
//

import XCTest

final class RecordEditViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testRecordEditViewTests() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "RecordEditViewTests"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.buttons["show"].waitForExistence(timeout: 3))
        app.buttons["show"].tap()
        
        XCTAssertTrue(app.buttons["button_add_time_record"].waitForExistence(timeout: 3))
        app.buttons["button_add_time_record"].tap()
        
        XCTAssertTrue(app.tabs["power.circle.fill"].waitForExistence(timeout: 3))
        app.tabs["power.circle.fill"].tap()
        
        XCTAssertTrue(app.buttons["button_add_uptime_record"].waitForExistence(timeout: 3))
        app.buttons["button_add_uptime_record"].tap()
        
        XCTAssertTrue(app.buttons["button_close"].waitForExistence(timeout: 3))
        app.buttons.matching(identifier: "button_close").firstMatch.tap()
        
        sleep(1)
        
        XCTAssertTrue(app.staticTexts["time_record_count"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["time_record_count"].value as! String, "1")
        
        XCTAssertTrue(app.staticTexts["uptime_record_count"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["uptime_record_count"].value as! String, "1")
    }
}
