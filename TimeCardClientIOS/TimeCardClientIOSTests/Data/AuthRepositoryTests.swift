//
//  AuthRepositoryTests.swift
//  TimeCardClientIOSTests
//
//  Created by uhimania on 2026/08/18.
//

import Foundation
import Testing

@testable import TimeCardClientIOS

struct AuthRepositoryTests {

    @Test func testRegister() async throws {
        let network = FakeNetworkDataSource()
        let secure = FakeSecureDataSource()
        let repository = DefaultAuthRepository(network, secure)
        
        let mail = "mail@test.com"
        let password = "pass"
        try await repository.register(mail: mail, password: password)
        #expect(network.mail == mail)
        #expect(network.password == password)
    }
    
    @Test func testVerify() async throws {
        let network = FakeNetworkDataSource()
        let secure = FakeSecureDataSource()
        let repository = DefaultAuthRepository(network, secure)
        
        let mail = "mail@test.com"
        let verifyCode = "code"
        let accessToken = "aaa"
        let refreshToken = "bbb"
        network.accessToken = accessToken
        network.refreshToken = refreshToken
        try await repository.verify(mail: mail, verifyCode: verifyCode)
        #expect(network.mail == mail)
        #expect(network.verifyCode == verifyCode)
        #expect(try secure.load(forKey: Constants.accessTokenKey) == accessToken)
        #expect(try secure.load(forKey: Constants.refreshTokenKey) == refreshToken)
    }
    
    @Test func testLogin() async throws {
        let network = FakeNetworkDataSource()
        let secure = FakeSecureDataSource()
        let repository = DefaultAuthRepository(network, secure)
        
        let mail = "mail@test.com"
        let password = "pass"
        let accessToken = "aaa"
        let refreshToken = "bbb"
        network.accessToken = accessToken
        network.refreshToken = refreshToken
        try await repository.login(mail: mail, password: password)
        #expect(network.mail == mail)
        #expect(network.password == password)
        #expect(try secure.load(forKey: Constants.accessTokenKey) == accessToken)
        #expect(try secure.load(forKey: Constants.refreshTokenKey) == refreshToken)
    }
    
    @Test func testRefresh() async throws {
        let network = FakeNetworkDataSource()
        let secure = FakeSecureDataSource()
        let repository = DefaultAuthRepository(network, secure)
        
        let token = "token"
        let accessToken = "aaa"
        let refreshToken = "bbb"
        network.accessToken = accessToken
        network.refreshToken = refreshToken
        try secure.save(token, forKey: Constants.refreshTokenKey)
        try await repository.refresh()
        #expect(network.token == token)
        #expect(try secure.load(forKey: Constants.accessTokenKey) == accessToken)
        #expect(try secure.load(forKey: Constants.refreshTokenKey) == refreshToken)
    }
    
    @Test func testIsLoggedIn() async throws {
        let network = FakeNetworkDataSource()
        let secure = FakeSecureDataSource()
        let repository = DefaultAuthRepository(network, secure)
        #expect(repository.isLoggedIn() == false)
        
        try secure.save("aaa", forKey: Constants.accessTokenKey)
        #expect(repository.isLoggedIn() == true)
    }
    
    @Test func testGetAccessToken() async throws {
        let network = FakeNetworkDataSource()
        let secure = FakeSecureDataSource()
        let repository = DefaultAuthRepository(network, secure)
        #expect(repository.getAccessToken() == "")
        
        let token = "aaa"
        try secure.save(token, forKey: Constants.accessTokenKey)
        #expect(repository.getAccessToken() == token)
    }
    
    class FakeNetworkDataSource: AuthNetworkDataSource {
        var mail: String = ""
        var password: String = ""
        var verifyCode: String = ""
        var token: String = ""
        var accessToken: String = ""
        var refreshToken: String = ""
        
        func register(mail: String, password: String) async throws {
            self.mail = mail
            self.password = password
        }
        
        func verify(mail: String, verifyCode: String) async throws -> (accessToken: String, refreshToken: String) {
            self.mail = mail
            self.verifyCode = verifyCode
            return (accessToken, refreshToken)
        }
        
        func login(mail: String, password: String) async throws -> (accessToken: String, refreshToken: String) {
            self.mail = mail
            self.password = password
            return (accessToken, refreshToken)
        }
        
        func refresh(token: String) async throws -> (accessToken: String, refreshToken: String) {
            self.token = token
            return (accessToken, refreshToken)
        }
    }
    
    class FakeSecureDataSource: SecureDataSource {
        private var values: [String: String] = [:]
        
        func save(_ value: String, forKey key: String) throws {
            values[key] = value
        }
        
        func load(forKey key: String) throws -> String {
            values[key] ?? ""
        }
        
        func remove(forKey key: String) throws {
            values.removeValue(forKey: key)
        }
    }
}
