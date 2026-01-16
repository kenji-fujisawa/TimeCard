//
//  RecorderViewTests.swift
//  TimeCardUITests
//
//  Created by uhimania on 2025/12/26.
//

import XCTest

final class RecorderViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testRecorderView() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "RecorderViewTests"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.buttons["button_check_in"].waitForExistence(timeout: 3))
        
        app.buttons["button_check_in"].tap()
        
        XCTAssertTrue(app.buttons["button_check_out"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["button_break_start"].waitForExistence(timeout: 3))
        
        app.buttons["button_break_start"].tap()
        
        XCTAssertTrue(app.buttons["button_break_end"].waitForExistence(timeout: 3))
        
        app.buttons["button_break_end"].tap()
        
        XCTAssertTrue(app.buttons["button_check_out"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["button_break_start"].waitForExistence(timeout: 3))
        
        app.buttons["button_check_out"].tap()
        
        XCTAssertTrue(app.buttons["button_check_in"].waitForExistence(timeout: 3))
    }
}
