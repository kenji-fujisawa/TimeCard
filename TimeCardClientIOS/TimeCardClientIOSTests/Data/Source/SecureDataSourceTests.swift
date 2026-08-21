//
//  SecureDataSourceTests.swift
//  TimeCardClientIOSTests
//
//  Created by uhimania on 2026/08/14.
//

import Testing

@testable import TimeCardClientIOS

struct SecureDataSourceTests {

    @Test func testSaveLoadRemove() async throws {
        let source = KeyChainDataSource()
        
        let value = "val"
        let key = "TimeCardClientIOS.Test"
        try source.save(value, forKey: key)
        #expect(try source.load(forKey: key) == value)
        
        try source.remove(forKey: key)
        #expect(throws: KeyChainDataSource.KeyChainAccessError.self) {
            try source.load(forKey: key)
        }
    }

}
