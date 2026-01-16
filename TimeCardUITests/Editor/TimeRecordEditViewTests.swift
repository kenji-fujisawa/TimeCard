//
//  TimeRecordEditViewTests.swift
//  TimeCardUITests
//
//  Created by uhimania on 2025/12/29.
//

import XCTest

final class TimeRecordEditViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testSidebarView() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "TimeRecordEditViewTests"]
        app.launch()
        app.activate()
        
        // check initial value
        XCTAssertTrue(app.buttons["nav_link"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons["nav_link"].label, "09:45")
        XCTAssertEqual(app.cells.containing(.button, identifier: "nav_link").element(boundBy: 0).isSelected, true)
        
        // add time record
        XCTAssertTrue(app.buttons["button_add_time_record"].waitForExistence(timeout: 3))
        app.buttons["button_add_time_record"].tap()
        
        XCTAssertEqual(app.buttons.matching(identifier: "nav_link").count, 2)
        XCTAssertEqual(app.buttons.matching(identifier: "nav_link").element(boundBy: 0).label, "09:45")
        XCTAssertEqual(app.cells.containing(.button, identifier: "nav_link").element(boundBy: 0).isSelected, false)
        XCTAssertEqual(app.buttons.matching(identifier: "nav_link").element(boundBy: 1).label, "00:00")
        XCTAssertEqual(app.cells.containing(.button, identifier: "nav_link").element(boundBy: 1).isSelected, true)
        
        XCTAssertTrue(app.datePickers["date_check_in"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.datePickers["date_check_in"].value as! String, "Unsafe value, description '2025-12-28 15:00:00 +0000'")
        
        // select time record
        app.buttons.matching(identifier: "nav_link").element(boundBy: 0).tap()
        
        XCTAssertTrue(app.datePickers["date_check_in"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.datePickers["date_check_in"].value as! String, "Unsafe value, description '2025-12-29 00:45:30 +0000'")
        
        // remove time record
        XCTAssertEqual(app.buttons.matching(identifier: "button_remove_time_confirm").count, 2)
        app.buttons.matching(identifier: "button_remove_time_confirm").element(boundBy: 1).tap()
        
        XCTAssertTrue(app.buttons["button_remove_time_record"].waitForExistence(timeout: 3))
        app.buttons["button_remove_time_record"].tap()
        
        XCTAssertEqual(app.buttons.matching(identifier: "nav_link").count, 1)
        XCTAssertEqual(app.buttons.matching(identifier: "nav_link").element(boundBy: 0).label, "09:45")
        XCTAssertEqual(app.cells.containing(.button, identifier: "nav_link").element(boundBy: 0).isSelected, true)
        
        // re-add and remove another record
        XCTAssertTrue(app.buttons["button_add_time_record"].waitForExistence(timeout: 3))
        app.buttons["button_add_time_record"].tap()
        
        XCTAssertEqual(app.buttons.matching(identifier: "button_remove_time_confirm").count, 2)
        app.buttons.matching(identifier: "button_remove_time_confirm").element(boundBy: 1).tap()
        XCTAssertEqual(app.buttons.matching(identifier: "button_remove_time_confirm").count, 1)
        app.buttons.matching(identifier: "button_remove_time_confirm").element(boundBy: 0).tap()
        
        XCTAssertTrue(app.buttons["button_remove_time_record"].waitForExistence(timeout: 3))
        app.buttons["button_remove_time_record"].tap()
        
        XCTAssertEqual(app.buttons.matching(identifier: "nav_link").count, 1)
        XCTAssertEqual(app.buttons.matching(identifier: "nav_link").element(boundBy: 0).label, "00:00")
        XCTAssertEqual(app.cells.containing(.button, identifier: "nav_link").element(boundBy: 0).isSelected, true)
        
        // edit check in
        XCTAssertTrue(app.datePickers["date_check_in"].waitForExistence(timeout: 3))
        app.datePickers["date_check_in"].tap()
        app.datePickers["date_check_in"].typeText("29/15")
        
        XCTAssertEqual(app.buttons.matching(identifier: "nav_link").element(boundBy: 0).label, "15:00")
        XCTAssertEqual(app.cells.containing(.button, identifier: "nav_link").element(boundBy: 0).isSelected, true)
    }

    func testDetailView() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "TimeRecordEditViewTests"]
        app.launch()
        app.activate()
        
        // check initial value
        XCTAssertTrue(app.datePickers["date_check_in"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.datePickers["date_check_in"].value as! String, "Unsafe value, description '2025-12-29 00:45:30 +0000'")
        
        XCTAssertTrue(app.datePickers["date_check_out"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.datePickers["date_check_out"].value as! String, "Unsafe value, description '2025-12-29 17:12:38 +0000'")
        
        XCTAssertTrue(app.datePickers["date_break_start"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.datePickers["date_break_start"].value as! String, "Unsafe value, description '2025-12-29 14:48:12 +0000'")
        
        XCTAssertTrue(app.datePickers["date_break_end"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.datePickers["date_break_end"].value as! String, "Unsafe value, description '2025-12-29 16:33:48 +0000'")
        
        // add break time
        XCTAssertTrue(app.buttons["button_add_break_time"].waitForExistence(timeout: 3))
        app.buttons["button_add_break_time"].tap()
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").count, 2)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").element(boundBy: 0).value as! String, "Unsafe value, description '2025-12-29 00:45:30 +0000'")
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").element(boundBy: 1).value as! String, "Unsafe value, description '2025-12-29 14:48:12 +0000'")
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_end").count, 2)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_end").element(boundBy: 0).value as! String, "Unsafe value, description '2025-12-29 00:45:30 +0000'")
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_end").element(boundBy: 1).value as! String, "Unsafe value, description '2025-12-29 16:33:48 +0000'")
        
        // remove break time
        XCTAssertEqual(app.buttons.matching(identifier: "button_remove_break_confirm").count, 2)
        app.buttons.matching(identifier: "button_remove_break_confirm").element(boundBy: 0).tap()
        
        XCTAssertTrue(app.buttons["button_remove_break_time"].waitForExistence(timeout: 3))
        app.buttons["button_remove_break_time"].tap()
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").count, 1)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").element(boundBy: 0).value as! String, "Unsafe value, description '2025-12-29 14:48:12 +0000'")
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_end").count, 1)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_end").element(boundBy: 0).value as! String, "Unsafe value, description '2025-12-29 16:33:48 +0000'")
        
        // re-add and remove another record
        XCTAssertTrue(app.buttons["button_add_break_time"].waitForExistence(timeout: 3))
        app.buttons["button_add_break_time"].tap()
        
        XCTAssertEqual(app.buttons.matching(identifier: "button_remove_break_confirm").count, 2)
        app.buttons.matching(identifier: "button_remove_break_confirm").element(boundBy: 0).tap()
        XCTAssertEqual(app.buttons.matching(identifier: "button_remove_break_confirm").count, 1)
        app.buttons.matching(identifier: "button_remove_break_confirm").element(boundBy: 0).tap()
        
        XCTAssertTrue(app.buttons["button_remove_break_time"].waitForExistence(timeout: 3))
        app.buttons["button_remove_break_time"].tap()
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").count, 1)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").element(boundBy: 0).value as! String, "Unsafe value, description '2025-12-29 00:45:30 +0000'")
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_end").count, 1)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_end").element(boundBy: 0).value as! String, "Unsafe value, description '2025-12-29 00:45:30 +0000'")
    }
}
