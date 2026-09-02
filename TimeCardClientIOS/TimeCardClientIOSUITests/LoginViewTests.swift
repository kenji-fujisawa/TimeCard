//
//  LoginViewTests.swift
//  TimeCardClientIOSUITests
//
//  Created by uhimania on 2026/09/01.
//

import XCTest

final class LoginViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testLogin() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "LoginViewTests"]
        app.launch()

        XCTAssertTrue(app.buttons["update"].waitForExistence(timeout: 3))
        
        app.buttons["update"].tap()
        XCTAssertEqual(app.staticTexts["text_login"].label, "logged out")
        
        app.textFields["メールアドレス"].tap()
        app.textFields["メールアドレス"].typeText("mail@test.com")
        app.secureTextFields["パスワード"].tap()
        app.secureTextFields["パスワード"].typeText("pass")
        app.buttons["ログイン"].tap()
        
        app.buttons["update"].tap()
        XCTAssertEqual(app.staticTexts["text_login"].label, "logged in")
    }
    
    func testRegister() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "LoginViewTests"]
        app.launch()

        XCTAssertTrue(app.buttons["update"].waitForExistence(timeout: 3))
        
        app.buttons["update"].tap()
        XCTAssertEqual(app.staticTexts["text_login"].label, "logged out")
        
        app.buttons["ユーザー登録はこちら"].tap()
        
        XCTAssertTrue(app.buttons["登録"].waitForExistence(timeout: 3))
        
        app.textFields["メールアドレス"].tap()
        app.textFields["メールアドレス"].typeText("mail@test.com")
        app.secureTextFields["パスワード"].tap()
        app.secureTextFields["パスワード"].typeText("pass")
        app.secureTextFields["パスワード（確認用）"].tap()
        app.secureTextFields["パスワード（確認用）"].typeText("pass")
        app.buttons["登録"].tap()
        
        XCTAssertTrue(app.buttons["認証"].waitForExistence(timeout: 3))
        
        app.textFields["認証コード"].tap()
        app.textFields["認証コード"].typeText("123456")
        app.buttons["認証"].tap()
        
        app.buttons["update"].tap()
        XCTAssertEqual(app.staticTexts["text_login"].label, "logged in")
    }
}
