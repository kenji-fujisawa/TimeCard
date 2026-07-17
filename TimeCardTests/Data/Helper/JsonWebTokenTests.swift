//
//  JsonWebTokenTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2026/05/07.
//

import Foundation
import Testing

@testable import TimeCard

struct JsonWebTokenTests {

    @Test func testJWT() async throws {
        let sub = "123456"
        var token = try JWT.encode(sub: sub, exp: Date(timeIntervalSinceNow: 60))
        #expect(try JWT.decode(token) == sub)
        
        token = try JWT.encode(sub: sub, exp: .now)
        #expect(throws: JWT.JWTError.expired) {
            try JWT.decode(token)
        }
    }

    @Test func testInvalidJWT() async throws {
        #expect(throws: JWT.JWTError.invalidFormat) {
            try JWT.decode("")
        }
        
        #expect(throws: JWT.JWTError.invalidSignature) {
            try JWT.decode("eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTYiLCJpc3MiOiJUaW1lQ2FyZCIsImV4cCI6Nzk5ODMxMzI3LjE1Nzc1LCJhdWQiOiJUaW1lQ2FyZENsaWVudCJ9.test")
        }
        
        #expect(throws: JWT.JWTError.invalidHeader) {
            try JWT.decode("test.eyJzdWIiOiIxMjM0NTYiLCJpc3MiOiJUaW1lQ2FyZCIsImV4cCI6Nzk5ODMxMzI3LjE1Nzc1LCJhdWQiOiJUaW1lQ2FyZENsaWVudCJ9.yAwe_6wMiouJo0b5yN4Zc8d9-X-qfXepHZhfMdkLaJI")
        }
        
        #expect(throws: JWT.JWTError.invalidAlgorithm) {
            try JWT.decode("eyJ0eXAiOiJKV1QiLCJhbGciOiIifQ.eyJleHAiOjYzMTEzOTA0MDAwLCJzdWIiOiIxMjM0NTYiLCJhdWQiOiJUaW1lQ2FyZENsaWVudCIsImlzcyI6IlRpbWVDYXJkIn0.oiuw4H8e12tZyMttdDToII_0pIYMvXwGBqUCGVa39YI")
        }
        
        #expect(throws: JWT.JWTError.invalidType) {
            try JWT.decode("eyJhbGciOiJIUzI1NiIsInR5cCI6IiJ9.eyJleHAiOjYzMTEzOTA0MDAwLCJpc3MiOiJUaW1lQ2FyZCIsInN1YiI6IjEyMzQ1NiIsImF1ZCI6IlRpbWVDYXJkQ2xpZW50In0.fuyuxdAOGbFd8a8UmpnqxDCcOkJRg1MwiWcOHmpeFNE")
        }
        
        #expect(throws: JWT.JWTError.invalidPayload) {
            try JWT.decode("eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.test.3-8GVnimQkEf7swyP6QHXIWt6WSSRSKMpvfp9X9kem8")
        }
        
        #expect(throws: JWT.JWTError.invalidIssuer) {
            try JWT.decode("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIiLCJleHAiOjYzMTEzOTA0MDAwLCJhdWQiOiJUaW1lQ2FyZENsaWVudCIsInN1YiI6IjEyMzQ1NiJ9.lE8qaq2Pov5YgiW5wzZMesCXhEcWzb96lbJECKVeljI")
        }
        
        #expect(throws: JWT.JWTError.invalidAudience) {
            try JWT.decode("eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTYiLCJpc3MiOiJUaW1lQ2FyZCIsImF1ZCI6IiIsImV4cCI6NjMxMTM5MDQwMDB9.4nQX6tL2OZS1_8iIVNESL0YA1VPya2D6Xr4HeiKlSXU")
        }
    }
}
