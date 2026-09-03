//
//  AuthNetworkDataSourceTests.swift
//  TimeCardClientIOSTests
//
//  Created by uhimania on 2026/08/20.
//

import OHHTTPStubs
import OHHTTPStubsSwift
import Testing

@testable import TimeCardClientIOS

@Suite(.serialized)
class AuthNetworkDataSourceTests {
    
    deinit {
        HTTPStubs.removeAllStubs()
    }
    
    @Test func testRegister_success() async throws {
        var request: URLRequest? = nil
        var requestBody: Data? = nil
        stub(condition: isHost("192.168.4.33")) { req in
            request = req
            requestBody = req.ohhttpStubs_httpBody
            
            return HTTPStubsResponse(data: Data(), statusCode: 201, headers: nil)
        }
        
        guard let url = URL(string: "http://192.168.4.33:8080") else {
            Issue.record()
            return
        }
        let source = DefaultAuthNetworkDataSource(url)
        let mail = "mail@test.com"
        let password = "pass"
        try await source.register(mail: mail, password: password)
        
        #expect(request?.url?.path() == "/timecard/auth/register")
        #expect(request?.httpMethod == "POST")
        
        let json = try JSONSerialization.jsonObject(with: requestBody ?? Data()) as? [String: String]
        #expect(json?["mail"] == mail)
        #expect(json?["password"] == password)
    }
    
    @Test func testRegister_fail() async throws {
        stub(condition: isHost("192.168.4.33")) { req in
            return HTTPStubsResponse(data: Data(), statusCode: 404, headers: nil)
        }
        
        guard let url = URL(string: "http://192.168.4.33:8080") else {
            Issue.record()
            return
        }
        let source = DefaultAuthNetworkDataSource(url)
        let mail = "mail@test.com"
        let password = "pass"
        await #expect(throws: DefaultAuthNetworkDataSource.NetworkError.self) {
            try await source.register(mail: mail, password: password)
        }
    }
    
    @Test func testVerify_success() async throws {
        var request: URLRequest? = nil
        var requestBody: Data? = nil
        let accessToken = "aaa"
        let refreshToken = "bbb"
        stub(condition: isHost("192.168.4.33")) { req in
            request = req
            requestBody = req.ohhttpStubs_httpBody
            
            let response = """
                {
                    "accessToken":  "\(accessToken)",
                    "refreshToken": "\(refreshToken)"
                }
                """
            return HTTPStubsResponse(data: response.data(using: .utf8) ?? Data(), statusCode: 200, headers: nil)
        }
        
        guard let url = URL(string: "http://192.168.4.33:8080") else {
            Issue.record()
            return
        }
        let source = DefaultAuthNetworkDataSource(url)
        let mail = "mail@test.com"
        let verifyCode = "code"
        let response = try await source.verify(mail: mail, verifyCode: verifyCode)
        
        #expect(request?.url?.path() == "/timecard/auth/verify")
        #expect(request?.httpMethod == "POST")
        
        let json = try JSONSerialization.jsonObject(with: requestBody ?? Data()) as? [String: String]
        #expect(json?["mail"] == mail)
        #expect(json?["verifyCode"] == verifyCode)
        
        #expect(response.accessToken == accessToken)
        #expect(response.refreshToken == refreshToken)
    }
    
    @Test func testVerify_fail() async throws {
        stub(condition: isHost("192.168.4.33")) { req in
            return HTTPStubsResponse(data: Data(), statusCode: 404, headers: nil)
        }
        
        guard let url = URL(string: "http://192.168.4.33:8080") else {
            Issue.record()
            return
        }
        let source = DefaultAuthNetworkDataSource(url)
        let mail = "mail@test.com"
        let verifyCode = "code"
        await #expect(throws: DefaultAuthNetworkDataSource.NetworkError.self) {
            try await source.verify(mail: mail, verifyCode: verifyCode)
        }
    }
    
    @Test func testLogin_success() async throws {
        var request: URLRequest? = nil
        var requestBody: Data? = nil
        let accessToken = "aaa"
        let refreshToken = "bbb"
        stub(condition: isHost("192.168.4.33")) { req in
            request = req
            requestBody = req.ohhttpStubs_httpBody
            
            let response = """
                {
                    "accessToken":  "\(accessToken)",
                    "refreshToken": "\(refreshToken)"
                }
                """
            return HTTPStubsResponse(data: response.data(using: .utf8) ?? Data(), statusCode: 200, headers: nil)
        }
        
        guard let url = URL(string: "http://192.168.4.33:8080") else {
            Issue.record()
            return
        }
        let source = DefaultAuthNetworkDataSource(url)
        let mail = "mail@test.com"
        let password = "pass"
        let response = try await source.login(mail: mail, password: password)
        
        #expect(request?.url?.path() == "/timecard/auth/login")
        #expect(request?.httpMethod == "POST")
        
        let json = try JSONSerialization.jsonObject(with: requestBody ?? Data()) as? [String: String]
        #expect(json?["mail"] == mail)
        #expect(json?["password"] == password)
        
        #expect(response.accessToken == accessToken)
        #expect(response.refreshToken == refreshToken)
    }
    
    @Test func testLogin_fail() async throws {
        stub(condition: isHost("192.168.4.33")) { req in
            return HTTPStubsResponse(data: Data(), statusCode: 404, headers: nil)
        }
        
        guard let url = URL(string: "http://192.168.4.33:8080") else {
            Issue.record()
            return
        }
        let source = DefaultAuthNetworkDataSource(url)
        let mail = "mail@test.com"
        let password = "pass"
        await #expect(throws: DefaultAuthNetworkDataSource.NetworkError.self) {
            try await source.login(mail: mail, password: password)
        }
    }
    
    @Test func testRefresh_success() async throws {
        var request: URLRequest? = nil
        var requestBody: Data? = nil
        let accessToken = "aaa"
        let refreshToken = "bbb"
        stub(condition: isHost("192.168.4.33")) { req in
            request = req
            requestBody = req.ohhttpStubs_httpBody
            
            let response = """
                {
                    "accessToken":  "\(accessToken)",
                    "refreshToken": "\(refreshToken)"
                }
                """
            return HTTPStubsResponse(data: response.data(using: .utf8) ?? Data(), statusCode: 200, headers: nil)
        }
        
        guard let url = URL(string: "http://192.168.4.33:8080") else {
            Issue.record()
            return
        }
        let source = DefaultAuthNetworkDataSource(url)
        let token = "refresh"
        let response = try await source.refresh(token: token)
        
        #expect(request?.url?.path() == "/timecard/auth/refresh")
        #expect(request?.httpMethod == "POST")
        
        let json = try JSONSerialization.jsonObject(with: requestBody ?? Data()) as? [String: String]
        #expect(json?["refreshToken"] == token)
        
        #expect(response.accessToken == accessToken)
        #expect(response.refreshToken == refreshToken)
    }
    
    @Test func testRefresh_fail() async throws {
        stub(condition: isHost("192.168.4.33")) { req in
            return HTTPStubsResponse(data: Data(), statusCode: 404, headers: nil)
        }
        
        guard let url = URL(string: "http://192.168.4.33:8080") else {
            Issue.record()
            return
        }
        let source = DefaultAuthNetworkDataSource(url)
        let token = "refresh"
        await #expect(throws: DefaultAuthNetworkDataSource.NetworkError.self) {
            try await source.refresh(token: token)
        }
    }
}
