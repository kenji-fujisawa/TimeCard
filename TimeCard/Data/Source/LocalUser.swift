//
//  LocalUser.swift
//  TimeCard
//
//  Created by uhimania on 2026/04/28.
//

import Foundation
import SwiftData

extension TimeCardSchema_v4 {
    @Model
    class User {
        #Index<User>([\.mail])
        
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
        
        init(id: UUID = UUID(), mail: String, password: String = "", verifyCode: String = "", verifyCodeExpires: Date = .now, verifyAttempts: Int = 0, refreshToken: String = "", loginAttempts: Int = 0, lastAttempt: Date? = nil, locked: Date? = nil) {
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
}

typealias LocalUser = TimeCardSchema_v4.User
