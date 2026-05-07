//
//  User.swift
//  TimeCard
//
//  Created by uhimania on 2026/04/28.
//

import Foundation

struct User: Equatable {
    var mail: String
    var password: String
    var verifyCode: String
    var verifyCodeExpires: Date
    var verifyAttempts: Int
    
    init(mail: String, password: String, verifyCode: String = "", verifyCodeExpires: Date = .now, verifyAttempts: Int = 0) {
        self.mail = mail
        self.password = password
        self.verifyCode = verifyCode
        self.verifyCodeExpires = verifyCodeExpires
        self.verifyAttempts = verifyAttempts
    }
}
