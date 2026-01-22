//
//  ContentViewTests.swift
//  TimeCardClientIOSUITests
//
//  Created by uhimania on 2026/01/09.
//

import XCTest

final class ContentViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testLoading() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "ContentViewTests"]
        app.launch()

        // show loading
        var expect = expectation(for: NSPredicate(format: "count > 0"), evaluatedWith: app.activityIndicators)
        wait(for: [expect], timeout: 3)
        XCTAssertTrue(app.activityIndicators.count > 0)
        
        // show calendar view
        expect = expectation(for: NSPredicate(format: "count > 0"), evaluatedWith: app.buttons)
        wait(for: [expect], timeout: 3)
        XCTAssertEqual(app.buttons["text_date"].firstMatch.label, "01(月)")
        
        // tap next month
        XCTAssertTrue(app.buttons["button_next"].waitForExistence(timeout: 3))
        app.buttons["button_next"].tap()
        
        // show loading
        expect = expectation(for: NSPredicate(format: "count > 0"), evaluatedWith: app.activityIndicators)
        wait(for: [expect], timeout: 3)
        XCTAssertTrue(app.activityIndicators.count > 0)
        
        // show calendar view
        expect = expectation(for: NSPredicate(format: "count > 0"), evaluatedWith: app.buttons)
        wait(for: [expect], timeout: 3)
        XCTAssertEqual(app.buttons["text_date"].firstMatch.label, "01(木)")
    }
    
    func testToast() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "ContentViewTests"]
        app.launch()

        XCTAssertTrue(app.buttons["button_prev"].waitForExistence(timeout: 5))
        app.buttons["button_prev"].tap()
        
        XCTAssertTrue(app.staticTexts["text_message"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["text_message"].label, "データを取得できませんでした")
    }
}
