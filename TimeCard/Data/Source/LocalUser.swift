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
        @Model
        class RefreshToken {
            #Index<RefreshToken>([\.token])
            
            var token: String
            var status: RefreshTokenStatus
            var expire: Date
            var parent: User?
            
            init(token: String, status: RefreshTokenStatus, expire: Date, parent: User? = nil) {
                self.token = token
                self.status = status
                self.expire = expire
                self.parent = parent
            }
        }
        
        #Index<User>([\.mail])
        
        var id: UUID
        var mail: String
        var password: String
        var verifyCode: String
        var verifyCodeExpires: Date
        var verifyAttempts: Int
        var loginAttempts: Int
        var lastAttempt: Date?
        var locked: Date?
        
        @Relationship(deleteRule: .cascade, inverse: \RefreshToken.parent)
        var refreshTokens: [RefreshToken]
        
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
}

typealias LocalUser = TimeCardSchema_v4.User
