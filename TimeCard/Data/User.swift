//
//  User.swift
//  TimeCard
//
//  Created by uhimania on 2026/04/28.
//

import Foundation

struct User: Equatable {
    var id: UUID
    var mail: String
    var password: String
    var verifyCode: String
    var verifyCodeExpires: Date
    var verifyAttempts: Int
    var refreshToken: String
    var loginAttempts: Int
    var lastAttempt: Date?
    var locked: Date?
    
    var verified: Bool {
        verifyCode.isEmpty
    }
    
    init(id: UUID = UUID(), mail: String, password: String, verifyCode: String = "", verifyCodeExpires: Date = .now, verifyAttempts: Int = 0, refreshToken: String = "", loginAttempts: Int = 0, lastAttempt: Date? = nil, locked: Date? = nil) {
        self.id = id
        self.mail = mail
        self.password = password
        self.verifyCode = verifyCode
        self.verifyCodeExpires = verifyCodeExpires
        self.verifyAttempts = verifyAttempts
        self.refreshToken = refreshToken
        self.loginAttempts = loginAttempts
        self.lastAttempt = lastAttempt
        self.locked = locked
    }
}
