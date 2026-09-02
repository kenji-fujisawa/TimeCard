//
//  AuthURLSessionTests.swift
//  TimeCardClientIOSTests
//
//  Created by uhimania on 2026/08/19.
//

import OHHTTPStubs
import OHHTTPStubsSwift
import Testing

@testable import TimeCardClientIOS

@Suite(.serialized)
class AuthURLSessionTests {

    deinit {
        HTTPStubs.removeAllStubs()
    }
    
    @Test func testAccessToken() async throws {
        var request: URLRequest? = nil
        let response = "res"
        stub(condition: isHost("192.168.4.33")) { req in
            request = req
            
            return HTTPStubsResponse(data: response.data(using: .utf8) ?? Data(), statusCode: 200, headers: nil)
        }
        
        guard let url = URL(string: "http://192.168.4.33:8080/timecard/records") else {
            Issue.record()
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        
        let token = "aaa"
        let repository = FakeAuthRepository()
        repository.token = token
        
        let session = DefaultAuthURLSession(repository)
        let (data, res) = try await session.data(for: req)
        
        #expect(String(data: data, encoding: .utf8) == response)
        
        #expect((res as? HTTPURLResponse)?.statusCode == 200)
        
        #expect(request?.allHTTPHeaderFields?["Authorization"] == "Bearer \(token)")
        #expect(request?.url?.path() == "/timecard/records")
        #expect(request?.httpMethod == "GET")
    }
    
    @Test func testRefresh() async throws {
        var request: URLRequest? = nil
        let response = "res"
        var called = 0
        stub(condition: isHost("192.168.4.33")) { req in
            request = req
            called += 1
            
            if called == 1 {
                return HTTPStubsResponse(data: Data(), statusCode: 401, headers: nil)
            } else {
                return HTTPStubsResponse(data: response.data(using: .utf8) ?? Data(), statusCode: 200, headers: nil)
            }
        }
        
        guard let url = URL(string: "http://192.168.4.33:8080/timecard/records") else {
            Issue.record()
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        
        let token = "aaa"
        let refreshed = "bbb"
        let repository = FakeAuthRepository()
        repository.token = token
        repository.refreshedToken = refreshed
        
        let session = DefaultAuthURLSession(repository)
        let (data, res) = try await session.data(for: req)
        
        #expect(String(data: data, encoding: .utf8) == response)
        
        #expect((res as? HTTPURLResponse)?.statusCode == 200)
        
        #expect(request?.allHTTPHeaderFields?["Authorization"] == "Bearer \(refreshed)")
        #expect(request?.url?.path() == "/timecard/records")
        #expect(request?.httpMethod == "GET")
        
        #expect(called == 2)
    }
    
    class FakeAuthRepository: AuthRepository {
        func register(mail: String, password: String) async throws {}
        func verify(mail: String, verifyCode: String) async throws {}
        func login(mail: String, password: String) async throws {}
        func isLoggedIn() -> Bool { false }
        func onLogout(_ callback: @escaping () -> Void) {}
        
        var token = ""
        func getAccessToken() -> String {
            token
        }
        
        var refreshedToken = ""
        func refresh() async throws {
            token = refreshedToken
        }
    }
}
