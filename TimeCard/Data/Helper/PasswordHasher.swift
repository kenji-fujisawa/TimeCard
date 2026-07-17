//
//  PasswordHasher.swift
//  TimeCard
//
//  Created by uhimania on 2026/05/01.
//

import Argon2Swift
import Foundation

protocol PasswordHasher {
    func hash(_ password: String) async throws -> String
    func verify(password: String, hash: String) async throws -> Bool
}

class Argon2PasswordHasher: PasswordHasher {
    func hash(_ password: String) async throws -> String {
        return try await Task.detached {
            let salt = Salt.newSalt()
            return try Argon2Swift.hashPasswordString(password: password, salt: salt).encodedString()
        }.value
    }
    
    func verify(password: String, hash: String) async throws -> Bool {
        return try await Task.detached {
            return try Argon2Swift.verifyHashString(password: password, hash: hash)
        }.value
    }
}
