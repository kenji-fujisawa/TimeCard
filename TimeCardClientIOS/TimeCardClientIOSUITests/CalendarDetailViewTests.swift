//
//  CalendarDetailViewTests.swift
//  TimeCardClientIOSUITests
//
//  Created by uhimania on 2025/12/30.
//

import XCTest

final class CalendarDetailViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testInitialValues() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "CalendarDetailViewTests"]
        app.launch()
        
        // navigate to detail view
        XCTAssertTrue(app.buttons["link"].waitForExistence(timeout: 3))
        app.buttons["link"].tap()
        
        XCTAssertTrue(app.datePickers["date_check_in"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.datePickers["date_check_in"].buttons.firstMatch.value as! String, "09:12, Dec 29, 2025")
        
        XCTAssertTrue(app.datePickers["date_check_out"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.datePickers["date_check_out"].buttons.firstMatch.value as! String, "02:28, Dec 30, 2025")
        
        XCTAssertTrue(app.datePickers["date_break_start"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.datePickers["date_break_start"].buttons.firstMatch.value as! String, "23:45, Dec 29, 2025")
        
        XCTAssertTrue(app.datePickers["date_break_end"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.datePickers["date_break_end"].buttons.firstMatch.value as! String, "01:30, Dec 30, 2025")
    }
    
    func testTimeRecords() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "CalendarDetailViewTests"]
        app.launch()
        
        // navigate to detail view
        XCTAssertTrue(app.buttons["link"].waitForExistence(timeout: 3))
        app.buttons["link"].tap()
        
        // initial value
        XCTAssertEqual(app.datePickers.matching(identifier: "date_check_in").count, 1)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_check_in").element(boundBy: 0).buttons.firstMatch.value as! String, "09:12, Dec 29, 2025")
        
        // add time record
        XCTAssertTrue(app.buttons["button_add_time_record"].waitForExistence(timeout: 3))
        app.buttons["button_add_time_record"].tap()
        
        sleep(1)
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_check_in").count, 2)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_check_in").element(boundBy: 0).buttons.firstMatch.value as! String, "09:12, Dec 29, 2025")
        XCTAssertEqual(app.datePickers.matching(identifier: "date_check_in").element(boundBy: 1).buttons.firstMatch.value as! String, "00:00, Dec 29, 2025")
        
        // remove time record
        XCTAssertTrue(app.buttons["button_edit"].waitForExistence(timeout: 3))
        app.buttons["button_edit"].tap()
        
        XCTAssertEqual(app.images.matching(identifier: "minus.circle.fill").count, 3)
        app.images.matching(identifier: "minus.circle.fill").element(boundBy: 2).tap()
        
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 3))
        app.buttons["Delete"].tap()
        
        sleep(1)
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_check_in").count, 1)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_check_in").element(boundBy: 0).buttons.firstMatch.value as! String, "09:12, Dec 29, 2025")
        
        // re-add and remove another record
        XCTAssertTrue(app.buttons["button_add_time_record"].waitForExistence(timeout: 3))
        app.buttons["button_add_time_record"].tap()
        
        XCTAssertEqual(app.images.matching(identifier: "minus.circle.fill").count, 3)
        app.images.matching(identifier: "minus.circle.fill").element(boundBy: 0).tap()
        
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 3))
        app.buttons["Delete"].tap()
        
        sleep(1)
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_check_in").count, 1)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_check_in").element(boundBy: 0).buttons.firstMatch.value as! String, "00:00, Dec 29, 2025")
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").count, 0)
    }
    
    func testBreakTimes() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "CalendarDetailViewTests"]
        app.launch()
        
        // navigate to detail view
        XCTAssertTrue(app.buttons["link"].waitForExistence(timeout: 3))
        app.buttons["link"].tap()
        
        // initial value
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").count, 1)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").element(boundBy: 0).buttons.firstMatch.value as! String, "23:45, Dec 29, 2025")
        
        // add break time
        XCTAssertTrue(app.buttons["button_add_break_time"].waitForExistence(timeout: 3))
        app.buttons["button_add_break_time"].tap()
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").count, 2)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").element(boundBy: 0).buttons.firstMatch.value as! String, "23:45, Dec 29, 2025")
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").element(boundBy: 1).buttons.firstMatch.value as! String, "09:12, Dec 29, 2025")
        
        // remove break time
        XCTAssertTrue(app.buttons["button_edit"].waitForExistence(timeout: 3))
        app.buttons["button_edit"].tap()
        
        XCTAssertEqual(app.images.matching(identifier: "minus.circle.fill").count, 3)
        app.images.matching(identifier: "minus.circle.fill").element(boundBy: 2).tap()
        
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 3))
        app.buttons["Delete"].tap()
        
        sleep(1)
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").count, 1)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").element(boundBy: 0).buttons.firstMatch.value as! String, "23:45, Dec 29, 2025")
        
        // re-add and remove another record
        XCTAssertTrue(app.buttons["button_add_break_time"].waitForExistence(timeout: 3))
        app.buttons["button_add_break_time"].tap()
        
        XCTAssertEqual(app.images.matching(identifier: "minus.circle.fill").count, 3)
        app.images.matching(identifier: "minus.circle.fill").element(boundBy: 1).tap()
        
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 3))
        app.buttons["Delete"].tap()
        
        sleep(1)
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").count, 1)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").element(boundBy: 0).buttons.firstMatch.value as! String, "09:12, Dec 29, 2025")
        
        // close edit mode in order to refresh date picker
        XCTAssertTrue(app.buttons["button_edit"].waitForExistence(timeout: 3))
        app.buttons["button_edit"].tap()
        
        // another parent
        XCTAssertTrue(app.buttons["button_add_time_record"].waitForExistence(timeout: 3))
        app.buttons["button_add_time_record"].tap()
        
        XCTAssertEqual(app.buttons.matching(identifier: "button_add_break_time").count, 2)
        app.buttons.matching(identifier: "button_add_break_time").element(boundBy: 1).tap()
        
        XCTAssertTrue(app.buttons["button_edit"].waitForExistence(timeout: 3))
        app.buttons["button_edit"].tap()
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").count, 2)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").element(boundBy: 0).buttons.firstMatch.value as! String, "09:12, Dec 29, 2025")
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").element(boundBy: 1).buttons.firstMatch.value as! String, "00:00, Dec 29, 2025")
        
        XCTAssertEqual(app.images.matching(identifier: "minus.circle.fill").count, 4)
        app.images.matching(identifier: "minus.circle.fill").element(boundBy: 3).tap()
        
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 3))
        app.buttons["Delete"].tap()
        
        sleep(1)
        
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").count, 1)
        XCTAssertEqual(app.datePickers.matching(identifier: "date_break_start").element(boundBy: 0).buttons.firstMatch.value as! String, "09:12, Dec 29, 2025")
    }
    
    func testUpdateRecord() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "CalendarDetailViewTests"]
        app.launch()
        
        // initial value
        XCTAssertTrue(app.staticTexts["calendar_count"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["calendar_count"].label, "0")
        
        // navigate to detail view
        XCTAssertTrue(app.buttons["link"].waitForExistence(timeout: 3))
        app.buttons["link"].tap()
        
        // remove break time
        XCTAssertTrue(app.buttons["button_edit"].waitForExistence(timeout: 3))
        app.buttons["button_edit"].tap()
        
        XCTAssertEqual(app.images.matching(identifier: "minus.circle.fill").count, 2)
        app.images.matching(identifier: "minus.circle.fill").element(boundBy: 1).tap()
        
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 3))
        app.buttons["Delete"].tap()
        
        // navigate back
        XCTAssertTrue(app.buttons["BackButton"].waitForExistence(timeout: 3))
        app.buttons["BackButton"].tap()
        
        sleep(1)
        
        XCTAssertTrue(app.staticTexts["calendar_count"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["calendar_count"].label, "1")
        
        XCTAssertTrue(app.staticTexts["calendar_date"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["calendar_date"].label, "Dec 29")
        
        XCTAssertTrue(app.staticTexts["record_count"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["record_count"].label, "1")
        
        XCTAssertTrue(app.staticTexts["record_check_in"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["record_check_in"].label, "09:12")
        
        XCTAssertTrue(app.staticTexts["record_check_out"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["record_check_out"].label, "02:28")
        
        XCTAssertTrue(app.staticTexts["break_time_count"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["break_time_count"].label, "0")
    }
}
