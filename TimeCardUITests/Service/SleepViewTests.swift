//
//  SleepViewTests.swift
//  TimeCardUITests
//
//  Created by uhimania on 2026/01/14.
//

import XCTest

final class SleepViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testSleepView() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "SleepViewTests"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.staticTexts["state"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["state"].value as! String, "OffWork")
        
        XCTAssertTrue(app.buttons["sleep"].waitForExistence(timeout: 3))
        app.buttons["sleep"].tap()
        
        XCTAssertTrue(app.staticTexts["state"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["state"].value as! String, "OffWork")
        
        XCTAssertTrue(app.buttons["checkIn"].waitForExistence(timeout: 3))
        app.buttons["checkIn"].tap()
        
        XCTAssertTrue(app.staticTexts["state"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["state"].value as! String, "AtWork")
        
        XCTAssertTrue(app.buttons["sleep"].waitForExistence(timeout: 3))
        app.buttons["sleep"].tap()
        
        XCTAssertTrue(app.staticTexts["state"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["state"].value as! String, "AtBreak")
        
        XCTAssertTrue(app.buttons["wake"].waitForExistence(timeout: 3))
        app.buttons["wake"].tap()
        
        XCTAssertTrue(app.staticTexts["state"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["state"].value as! String, "AtWork")
    }
}
