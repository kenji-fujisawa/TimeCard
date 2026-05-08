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
        var id: UUID
        @Attribute(.unique) var mail: String
        var password: String
        var verifyCode: String
        var verifyCodeExpires: Date
        var verifyAttempts: Int
        
        init(id: UUID = UUID(), mail: String, password: String = "", verifyCode: String = "", verifyCodeExpires: Date = .now, verifyAttempts: Int = 0) {
            self.id = id
            self.mail = mail
            self.password = password
            self.verifyCode = verifyCode
            self.verifyCodeExpires = verifyCodeExpires
            self.verifyAttempts = verifyAttempts
        }
    }
}

typealias LocalUser = TimeCardSchema_v4.User
