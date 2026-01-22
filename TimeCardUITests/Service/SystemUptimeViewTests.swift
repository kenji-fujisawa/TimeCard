//
//  SystemUptimeViewTests.swift
//  TimeCardUITests
//
//  Created by uhimania on 2026/01/19.
//

import XCTest

final class SystemUptimeViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testSystemUptimeView() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "SystemUptimeViewTests"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.buttons["update"].waitForExistence(timeout: 3))
        app.buttons["update"].tap()
        
        sleep(3)
        
        XCTAssertTrue(app.staticTexts["launch"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["shutdown"].waitForExistence(timeout: 3))
        var launch = app.staticTexts["launch"].value as! String
        var shutdown = app.staticTexts["shutdown"].value as! String
        
        XCTAssertTrue(app.buttons["sleep"].waitForExistence(timeout: 3))
        app.buttons["sleep"].tap()
        
        sleep(3)
        
        XCTAssertEqual(app.staticTexts["launch"].value as! String, launch)
        XCTAssertNotEqual(app.staticTexts["shutdown"].value as! String, shutdown)
        launch = app.staticTexts["launch"].value as! String
        shutdown = app.staticTexts["shutdown"].value as! String
        
        XCTAssertTrue(app.staticTexts["start"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["end"].waitForExistence(timeout: 3))
        var start = app.staticTexts["start"].value as! String
        var end = app.staticTexts["end"].value as! String
        
        XCTAssertTrue(app.buttons["wake"].waitForExistence(timeout: 3))
        app.buttons["wake"].tap()
        
        sleep(3)
        
        XCTAssertEqual(app.staticTexts["launch"].value as! String, launch)
        XCTAssertNotEqual(app.staticTexts["shutdown"].value as! String, shutdown)
        XCTAssertEqual(app.staticTexts["start"].value as! String, start)
        XCTAssertNotEqual(app.staticTexts["end"].value as! String, end)
        
        launch = app.staticTexts["launch"].value as! String
        shutdown = app.staticTexts["shutdown"].value as! String
        start = app.staticTexts["start"].value as! String
        end = app.staticTexts["end"].value as! String
        
        XCTAssertTrue(app.buttons["terminate"].waitForExistence(timeout: 3))
        app.buttons["terminate"].tap()
        
        sleep(3)
        
        XCTAssertEqual(app.staticTexts["launch"].value as! String, launch)
        XCTAssertNotEqual(app.staticTexts["shutdown"].value as! String, shutdown)
        XCTAssertEqual(app.staticTexts["start"].value as! String, start)
        XCTAssertEqual(app.staticTexts["end"].value as! String, end)
    }
}
