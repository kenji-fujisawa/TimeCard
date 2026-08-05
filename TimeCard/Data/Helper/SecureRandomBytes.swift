//
//  SecureRandomBytes.swift
//  TimeCard
//
//  Created by uhimania on 2026/05/08.
//

import Foundation

enum SecureRandomBytes {
    struct SecureRandomBytesError: Error {
        let status: Int32
    }
    
    static func generate(length: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else { throw SecureRandomBytesError(status: status) }
        return Data(bytes)
    }
}
