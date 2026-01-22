//
//  ToastViewTests.swift
//  TimeCardClientIOSUITests
//
//  Created by uhimania on 2025/12/30.
//

import XCTest

final class ToastViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testToastView() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "ToastViewTests"]
        app.launch()

        XCTAssertEqual(app.staticTexts.matching(identifier: "text_message").count, 0)
        
        XCTAssertTrue(app.buttons["button_show_toast"].waitForExistence(timeout: 3))
        app.buttons["button_show_toast"].tap()
        
        XCTAssertTrue(app.staticTexts["text_message"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["text_message"].label, "test message")
        
        sleep(2)
        
        XCTAssertEqual(app.staticTexts.matching(identifier: "text_message").count, 0)
    }
}
