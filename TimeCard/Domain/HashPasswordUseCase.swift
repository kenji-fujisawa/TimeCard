//
//  HashPasswordUseCase.swift
//  TimeCard
//
//  Created by uhimania on 2026/05/01.
//

import CryptoKit
import Foundation

class HashPasswordUseCase {
    enum HashPasswordError: Error {
        case generateSecretFailed
    }
    
    private let urlForSecret = FileManager.default.temporaryDirectory.appendingPathComponent("TimeCard.secret")
    
    func execute(_ password: String) throws -> String {
        let secret = try getSecret()
        let key = SymmetricKey(data: Data(secret.utf8))
        let code = HMAC<SHA256>.authenticationCode(for: Data(password.utf8), using: key)
        return Data(code).base64EncodedString()
    }
    
    private func getSecret() throws -> String {
        if let data = try? Data(contentsOf: urlForSecret) {
            return data.base64EncodedString()
        }
        
        let length = 64
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else { throw HashPasswordError.generateSecretFailed }
        
        let secret = Data(bytes)
        try secret.write(to: urlForSecret)
        return secret.base64EncodedString()
    }
}
