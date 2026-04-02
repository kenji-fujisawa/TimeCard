//
//  SystemUptimeRecordEditViewTests.swift
//  TimeCardUITests
//
//  Created by uhimania on 2025/12/30.
//

import XCTest

final class SystemUptimeRecordEditViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testSidebarView() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "SystemUptimeRecordEditViewTests"]
        app.launch()
        app.activate()
        
        // check initial value
        XCTAssertTrue(app.staticTexts["nav_link"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["nav_link"].value as! String, "14:47")
        XCTAssertEqual(app.cells.containing(.staticText, identifier: "nav_link").element(boundBy: 0).isSelected, true)
        
        // add uptime record
        XCTAssertTrue(app.buttons["button_add_uptime_record"].waitForExistence(timeout: 3))
        app.buttons["button_add_uptime_record"].tap()
        
        XCTAssertEqual(app.staticTexts.matching(identifier: "nav_link").count, 2)
        XCTAssertEqual(app.staticTexts.matching(identifier: "nav_link").element(boundBy: 0).value as! String, "14:47")
        XCTAssertEqual(app.cells.containing(.staticText, identifier: "nav_link").element(boundBy: 0).isSelected, false)
        XCTAssertEqual(app.staticTexts.matching(identifier: "nav_link").element(boundBy: 1).value as! String, "00:00")
        XCTAssertEqual(app.cells.containing(.staticText, identifier: "nav_link").element(boundBy: 1).isSelected, true)
        
        XCTAssertTrue(app.datePickers["date_launch"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.datePickers["date_launch"].value as! String, "Unsafe value, description '2025-12-28 15:00:00 +0000'")
        
        // select uptime record
        app.staticTexts.matching(identifier: "nav_link").element(boundBy: 0).tap()
        
        XCTAssertTrue(app.datePickers["date_launch"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.datePickers["date_launch"].value as! String, "Unsafe value, description '2025-12-28 23:27:32 +0000'")
        
        // remove uptime record
        XCTAssertEqual(app.buttons.matching(identifier: "button_remove_uptime_confirm").count, 2)
        app.buttons.matching(identifier: "button_remove_uptime_confirm").element(boundBy: 1).tap()
        
        XCTAssertTrue(app.buttons["button_remove_uptime_record"].waitForExistence(timeout: 3))
        app.buttons["button_remove_uptime_record"].tap()
        
        XCTAssertEqual(app.staticTexts.matching(identifier: "nav_link").count, 1)
        XCTAssertEqual(app.staticTexts.matching(identifier: "nav_link").element(boundBy: 0).value as! String, "14:47")
        XCTAssertEqual(app.cells.containing(.staticText, identifier: "nav_link").element(boundBy: 0).isSelected, true)
        
        // re-add and remove another record
        XCTAssertTrue(app.buttons["button_add_uptime_record"].waitForExistence(timeout: 3))
        app.buttons["button_add_uptime_record"].tap()
        
        XCTAssertEqual(app.buttons.matching(identifier: "button_remove_uptime_confirm").count, 2)
        app.buttons.matching(identifier: "button_remove_uptime_confirm").element(boundBy: 1).tap()
        XCTAssertEqual(app.buttons.matching(identifier: "button_remove_uptime_confirm").count, 1)
        app.buttons.matching(identifier: "button_remove_uptime_confirm").element(boundBy: 0).tap()
        
        XCTAssertTrue(app.buttons["button_remove_uptime_record"].waitForExistence(timeout: 3))
        app.buttons["button_remove_uptime_record"].tap()
        
        XCTAssertEqual(app.staticTexts.matching(identifier: "nav_link").count, 1)
        XCTAssertEqual(app.staticTexts.matching(identifier: "nav_link").element(boundBy: 0).value as! String, "00:00")
        XCTAssertEqual(app.cells.containing(.staticText, identifier: "nav_link").element(boundBy: 0).isSelected, true)
        
        // edit check in
        XCTAssertTrue(app.datePickers["date_launch"].waitForExistence(timeout: 3))
        app.datePickers["date_launch"].tap()
        app.datePickers["date_launch"].typeText("29/15")
        
        XCTAssertEqual(app.staticTexts.matching(identifier: "nav_link").element(boundBy: 0).value as! String, "-15:00")
        XCTAssertEqual(app.cells.containing(.staticText, identifier: "nav_link").element(boundBy: 0).isSelected, true)
    }
    
    func testDetailView() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "SystemUptimeRecordEditViewTests"]
        app.launch()
        app.activate()
        
        // check initial value
        XCTAssertTrue(app.datePickers["date_launch"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.datePickers["date_launch"].value as! String, "Unsafe value, description '2025-12-28 23:27:32 +0000'")
        
        XCTAssertTrue(app.datePickers["date_shutdown"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.datePickers["date_shutdown"].value as! String, "Unsafe value, description '2025-12-29 14:59:58 +0000'")
        
        XCTAssertTrue(app.datePickers["date_sleep_start"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.datePickers["date_sleep_start"].value as! String, "Unsafe value, description '2025-12-29 03:30:20 +0000'")
        
        XCTAssertTrue(app.datePickers["date_sleep_end"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.datePickers["date_sleep_end"].value as! String, "Unsafe value, description '2025-12-29 04:15:18 +0000'")
        
        // add sleep record
        XCTAssertTrue(app.buttons["button_add_sleep_record"].waitForExistence(timeout: 3))
        app.buttons["button_add_sleep_record"].tap()
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_sleep_start").count, 2)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_sleep_start").element(boundBy: 0).value as! String, "Unsafe value, description '2025-12-29 03:30:20 +0000'")
        XCTAssertEqual(app.datePickers.matching(identifier: "date_sleep_start").element(boundBy: 1).value as! String, "Unsafe value, description '2025-12-28 23:27:32 +0000'")
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_sleep_end").count, 2)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_sleep_end").element(boundBy: 0).value as! String, "Unsafe value, description '2025-12-29 04:15:18 +0000'")
        XCTAssertEqual(app.datePickers.matching(identifier: "date_sleep_end").element(boundBy: 1).value as! String, "Unsafe value, description '2025-12-28 23:27:32 +0000'")
        
        // remove sleep record
        XCTAssertEqual(app.buttons.matching(identifier: "button_remove_sleep_confirm").count, 2)
        app.buttons.matching(identifier: "button_remove_sleep_confirm").element(boundBy: 1).tap()
        
        XCTAssertTrue(app.buttons["button_remove_sleep_record"].waitForExistence(timeout: 3))
        app.buttons["button_remove_sleep_record"].tap()
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_sleep_start").count, 1)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_sleep_start").element(boundBy: 0).value as! String, "Unsafe value, description '2025-12-29 03:30:20 +0000'")
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_sleep_end").count, 1)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_sleep_end").element(boundBy: 0).value as! String, "Unsafe value, description '2025-12-29 04:15:18 +0000'")
        
        // re-add and remove another record
        XCTAssertTrue(app.buttons["button_add_sleep_record"].waitForExistence(timeout: 3))
        app.buttons["button_add_sleep_record"].tap()
        
        XCTAssertEqual(app.buttons.matching(identifier: "button_remove_sleep_confirm").count, 2)
        app.buttons.matching(identifier: "button_remove_sleep_confirm").element(boundBy: 1).tap()
        XCTAssertEqual(app.buttons.matching(identifier: "button_remove_sleep_confirm").count, 1)
        app.buttons.matching(identifier: "button_remove_sleep_confirm").element(boundBy: 0).tap()
        
        XCTAssertTrue(app.buttons["button_remove_sleep_record"].waitForExistence(timeout: 3))
        app.buttons["button_remove_sleep_record"].tap()
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_sleep_start").count, 1)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_sleep_start").element(boundBy: 0).value as! String, "Unsafe value, description '2025-12-28 23:27:32 +0000'")
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_sleep_end").count, 1)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_sleep_end").element(boundBy: 0).value as! String, "Unsafe value, description '2025-12-28 23:27:32 +0000'")
    }
    
    func testResetDetailView() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "SystemUptimeRecordEditViewTests"]
        app.launch()
        app.activate()
        
        // add time record
        XCTAssertTrue(app.buttons["button_add_uptime_record"].waitForExistence(timeout: 3))
        app.buttons["button_add_uptime_record"].tap()
        
        // select time record
        app.staticTexts.matching(identifier: "nav_link").element(boundBy: 0).tap()
        
        // remove time record
        app.buttons.matching(identifier: "button_remove_uptime_confirm").element(boundBy: 1).tap()
        
        XCTAssertTrue(app.buttons["button_remove_uptime_record"].waitForExistence(timeout: 3))
        app.buttons["button_remove_uptime_record"].tap()
        
        app.buttons.matching(identifier: "button_remove_uptime_confirm").element(boundBy: 0).tap()
        
        XCTAssertTrue(app.buttons["button_remove_uptime_record"].waitForExistence(timeout: 3))
        app.buttons["button_remove_uptime_record"].tap()
        
        // check detail view
        XCTAssertEqual(app.datePickers.matching(identifier: "date_launch").count, 0)
    }
}
