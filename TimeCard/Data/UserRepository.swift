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
    func login(mail: String, password: String) throws -> String
    func verifyLogin(token: String) -> Bool
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
    
    enum LoginError: Error {
        case invalidMail
        case invalidPassword
        case invalidUser
    }
    
    private let verifyCodeExpireSeconds: TimeInterval = 10 * 60
    private let verifyAttemptsLimit = 5
    private let accessTokenExpireSeconds: TimeInterval = 10 * 60
    
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
    
    func login(mail: String, password: String) throws -> String {
        guard let user = try source.getUser(mail: mail) else { throw LoginError.invalidMail }
        guard user.password == (try hashPassword.execute(password)) else { throw LoginError.invalidPassword }
        guard user.verified else { throw LoginError.invalidUser }
        
        return try JWT.encode(sub: user.id.uuidString, exp: Date(timeIntervalSinceNow: accessTokenExpireSeconds))
    }
    
    func verifyLogin(token: String) -> Bool {
        guard let id = try? JWT.decode(token) else { return false }
        guard let uuid = UUID(uuidString: id) else { return false }
        guard let user = try? source.getUser(id: uuid) else { return false }
        guard user.verified else { return false }
        
        return true
    }
}
