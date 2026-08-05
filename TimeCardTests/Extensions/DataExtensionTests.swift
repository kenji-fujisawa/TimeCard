//
//  DataExtensionTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2026/05/07.
//

import Foundation
import Testing

@testable import TimeCard

struct DataExtensionTests {

    @Test func testBase64URLEncode() async throws {
        var text = "a>?"
        var value = Data(text.utf8).base64URLEncodedString()
        #expect(value == "YT4_")
        #expect(String(data: Data(base64URLEncoded: value) ?? Data(), encoding: .utf8) == text)
        
        text = "aa>?"
        value = Data(text.utf8).base64URLEncodedString()
        #expect(value == "YWE-Pw")
        #expect(String(data: Data(base64URLEncoded: value) ?? Data(), encoding: .utf8) == text)
    }

}
