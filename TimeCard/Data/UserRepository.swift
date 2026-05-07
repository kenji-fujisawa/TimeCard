//
//  UserRepository.swift
//  TimeCard
//
//  Created by uhimania on 2026/04/28.
//

import Foundation

protocol UserRepository {
    func register(mail: String, password: String) async throws
    func verify(mail: String, verifyCode: String) throws
}

class DefaultUserRepository: UserRepository {
    enum RegisterError: Error {
        case duplicateMail
        case invalidMail
        case invalidPassword
    }
    
    enum VerifyError: Error {
        case invalidMail
        case invalidCode
        case expiredCode
        case exceedAttempts
    }
    
    private let verifyCodeExpireSeconds: TimeInterval = 10 * 60
    private let verifyAttemptsLimit = 5
    
    private let source: LocalDataSource
    private let sendVerifyCode: SendVerifyCodeUseCase
    private let hashPassword: HashPasswordUseCase
    
    init(_ source: LocalDataSource, _ sendVerifyCode: SendVerifyCodeUseCase, _ hashPassword: HashPasswordUseCase) {
        self.source = source
        self.sendVerifyCode = sendVerifyCode
        self.hashPassword = hashPassword
    }
    
    func register(mail: String, password: String) async throws {
        let pattern = "^[\\w\\.\\-_]+@[\\w\\.\\-_]+\\.[a-zA-Z]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        guard predicate.evaluate(with: mail) else { throw RegisterError.invalidMail }
        guard !password.isEmpty else { throw RegisterError.invalidPassword }
        guard try source.getUser(mail: mail) == nil else { throw RegisterError.duplicateMail }
        
        let verifyCode = generateVerifyCode()
        let verifyCodeExpires = Date(timeIntervalSinceNow: verifyCodeExpireSeconds)
        let user = User(
            mail: mail,
            password: try hashPassword.execute(password),
            verifyCode: try hashPassword.execute(verifyCode),
            verifyCodeExpires: verifyCodeExpires
        )
        try source.insertUser(user)
        
        try await sendVerifyCode.execute(mail: mail, verifyCode: verifyCode)
    }
    
    private func generateVerifyCode() -> String {
        let length = 6
        let digits = "0123456789"
        
        var code = ""
        while code.count < length {
            code.append(digits.randomElement() ?? Character(""))
        }
        
        return code
    }
    
    func verify(mail: String, verifyCode: String) throws {
        guard var user = try source.getUser(mail: mail) else { throw VerifyError.invalidMail }
        
        guard user.verifyCodeExpires >= .now else {
            user.verifyAttempts += 1
            try source.updateUser(user)
            throw VerifyError.expiredCode
        }
        
        guard user.verifyAttempts < verifyAttemptsLimit else {
            user.verifyAttempts += 1
            try source.updateUser(user)
            throw VerifyError.exceedAttempts
        }
        
        guard user.verifyCode == (try hashPassword.execute(verifyCode)) else {
            user.verifyAttempts += 1
            try source.updateUser(user)
            throw VerifyError.invalidCode
        }
        
        user.verifyCode = ""
        user.verifyAttempts += 1
        try source.updateUser(user)
    }
}
