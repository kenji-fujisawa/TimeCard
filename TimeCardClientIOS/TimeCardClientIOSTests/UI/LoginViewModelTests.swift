//
//  LoginViewModelTests.swift
//  TimeCardClientIOSTests
//
//  Created by uhimania on 2026/08/31.
//

import Testing

@testable import TimeCardClientIOS

struct LoginViewModelTests {

    @Test func testLogin() async throws {
        let repository = FakeAuthRepository()
        let viewModel = LoginViewModel(repository)
        #expect(viewModel.isLoggedIn == false)
        
        viewModel.login()
        
        try await Task.sleep(for: .seconds(1))
        
        #expect(viewModel.error != nil)
        #expect(viewModel.isLoggedIn == false)
        #expect(repository.mail == nil)
        #expect(repository.password == nil)
        
        let mail = "test@mail.com"
        let password = "pass"
        viewModel.mail = mail
        viewModel.password = password
        viewModel.login()
        
        try await Task.sleep(for: .seconds(1))
        
        #expect(viewModel.error == nil)
        #expect(viewModel.isLoggedIn == true)
        #expect(repository.mail == mail)
        #expect(repository.password == password)
    }
    
    @Test func testRegister() async throws {
        let repository = FakeAuthRepository()
        let viewModel = LoginViewModel(repository)
        #expect(viewModel.isLoggedIn == false)
        
        viewModel.register()
        
        try await Task.sleep(for: .milliseconds(1))
        
        #expect(viewModel.error != nil)
        #expect(viewModel.isLoggedIn == false)
        #expect(repository.mail == nil)
        #expect(repository.password == nil)
        
        let mail = "test@mail.com"
        let password = "pass"
        viewModel.mail = mail
        viewModel.password = password
        viewModel.register()
        
        try await Task.sleep(for: .milliseconds(1))
        
        #expect(viewModel.error != nil)
        #expect(viewModel.isLoggedIn == false)
        #expect(repository.mail == nil)
        #expect(repository.password == nil)
        
        viewModel.passwordConfirm = password
        viewModel.register()
        
        try await Task.sleep(for: .milliseconds(1))
        
        #expect(viewModel.error == nil)
        #expect(viewModel.state == .verify)
        #expect(viewModel.isLoggedIn == false)
        #expect(repository.mail == mail)
        #expect(repository.password == password)
    }
    
    @Test func testVerify() async throws {
        let repository = FakeAuthRepository()
        let viewModel = LoginViewModel(repository)
        #expect(viewModel.isLoggedIn == false)
        
        viewModel.verify()
        
        try await Task.sleep(for: .milliseconds(1))
        
        #expect(viewModel.error != nil)
        #expect(viewModel.isLoggedIn == false)
        #expect(repository.mail == nil)
        #expect(repository.verifyCode == nil)
        
        let mail = "test@mail.com"
        let verifyCode = "code"
        viewModel.mail = mail
        viewModel.verifyCode = verifyCode
        viewModel.verify()
        
        try await Task.sleep(for: .milliseconds(1))
        
        #expect(viewModel.error == nil)
        #expect(viewModel.isLoggedIn == true)
        #expect(repository.mail == mail)
        #expect(repository.verifyCode == verifyCode)
    }
    
    class FakeAuthRepository: AuthRepository {
        var mail: String? = nil
        var password: String? = nil
        var verifyCode: String? = nil
        var loggedIn = false
        
        func register(mail: String, password: String) async throws {
            self.mail = mail
            self.password = password
        }
        
        func verify(mail: String, verifyCode: String) async throws {
            self.mail = mail
            self.verifyCode = verifyCode
            self.loggedIn = true
        }
        
        func login(mail: String, password: String) async throws {
            self.mail = mail
            self.password = password
            self.loggedIn = true
        }
        
        func refresh() async throws {}
        func isLoggedIn() -> Bool { loggedIn }
        func onLogout(_ callback: @escaping () -> Void) {}
        func getAccessToken() -> String { "" }
    }
}
