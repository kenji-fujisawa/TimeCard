//
//  User.swift
//  TimeCard
//
//  Created by uhimania on 2026/04/28.
//

import Foundation

enum RefreshTokenStatus: Codable {
    case valid
    case used
    case revoked
}

struct User: Equatable {
    struct RefreshToken: Equatable {
        var token: String
        var status: RefreshTokenStatus
        var expire: Date
        var userId: UUID?
    }
    
    var id: UUID
    var mail: String
    var password: String
    var verifyCode: String
    var verifyCodeExpires: Date
    var verifyAttempts: Int
    var loginAttempts: Int
    var lastAttempt: Date?
    var locked: Date?
    var refreshTokens: [RefreshToken]
    
    var verified: Bool {
        verifyCode.isEmpty
    }
    
    init(id: UUID = UUID(), mail: String, password: String, verifyCode: String = "", verifyCodeExpires: Date = .now, verifyAttempts: Int = 0, loginAttempts: Int = 0, lastAttempt: Date? = nil, locked: Date? = nil, refreshTokens: [RefreshToken] = []) {
        self.id = id
        self.mail = mail
        self.password = password
        self.verifyCode = verifyCode
        self.verifyCodeExpires = verifyCodeExpires
        self.verifyAttempts = verifyAttempts
        self.loginAttempts = loginAttempts
        self.lastAttempt = lastAttempt
        self.locked = locked
        self.refreshTokens = refreshTokens
    }
}
