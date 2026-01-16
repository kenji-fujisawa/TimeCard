//
//  MonthSelectorViewTests.swift
//  TimeCardUITests
//
//  Created by uhimania on 2025/12/29.
//

import XCTest

final class MonthSelectorViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testMonthSelectorView() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "MonthSelectorViewTests"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.staticTexts["text_month"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["text_month"].value as! String, "2025年12月")
        
        XCTAssertTrue(app.buttons["button_prev"].waitForExistence(timeout: 3))
        app.buttons["button_prev"].tap()
        
        XCTAssertEqual(app.staticTexts["text_month"].value as! String, "2025年11月")
        
        XCTAssertTrue(app.buttons["button_next"].waitForExistence(timeout: 3))
        app.buttons["button_next"].tap()
        app.buttons["button_next"].tap()
        
        XCTAssertEqual(app.staticTexts["text_month"].value as! String, "2026年1月")
    }
}
