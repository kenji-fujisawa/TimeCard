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
    
    var verified: Bool {
        verifyCode.isEmpty
    }
    
    init(id: UUID = UUID(), mail: String, password: String, verifyCode: String = "", verifyCodeExpires: Date = .now, verifyAttempts: Int = 0, refreshToken: String = "") {
        self.id = id
        self.mail = mail
        self.password = password
        self.verifyCode = verifyCode
        self.verifyCodeExpires = verifyCodeExpires
        self.verifyAttempts = verifyAttempts
        self.refreshToken = refreshToken
    }
}
