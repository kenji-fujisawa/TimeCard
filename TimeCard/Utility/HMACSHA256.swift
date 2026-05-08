//
//  HMACSHA256.swift
//  TimeCard
//
//  Created by uhimania on 2026/05/07.
//

import CryptoKit
import Foundation

enum HMACSHA256 {
    enum HMACSHA256Error: Error {
        case generateSecretFailed
    }
    
    private static let urlForSecret = FileManager.default.temporaryDirectory.appendingPathComponent("TimeCard.secret")
    
    static func computeHash(_ value: String) throws -> Data {
        let secret = try getSecret()
        let key = SymmetricKey(data: Data(secret.utf8))
        let code = HMAC<SHA256>.authenticationCode(for: Data(value.utf8), using: key)
        return Data(code)
    }
    
    private static func getSecret() throws -> String {
        if let data = try? Data(contentsOf: urlForSecret) {
            return data.base64EncodedString()
        }
        
        let length = 64
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else { throw HMACSHA256Error.generateSecretFailed }
        
        let secret = Data(bytes)
        try secret.write(to: urlForSecret)
        return secret.base64EncodedString()
    }
}
