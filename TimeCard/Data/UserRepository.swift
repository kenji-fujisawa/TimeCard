//
//  UserRepository.swift
//  TimeCard
//
//  Created by uhimania on 2026/04/28.
//

import Foundation

struct TokenPair {
    let accessToken: String
    let refreshToken: String
}

protocol UserRepository {
    func register(mail: String, password: String) async throws
    func verify(mail: String, verifyCode: String) throws
    func login(mail: String, password: String) async throws -> TokenPair
    func verifyLogin(token: String) -> Bool
    func refresh(token: String) throws -> TokenPair
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
    
    enum RefreshError: Error {
        case invalidToken
    }
    
    private let verifyCodeExpireSeconds: TimeInterval = 10 * 60
    private let verifyAttemptsLimit = 5
    private let accessTokenExpireSeconds: TimeInterval = 10 * 60
    private let refreshTokenExpireSeconds: TimeInterval = 30 * 24 * 60 * 60
    
    private let source: LocalDataSource
    private let sendVerifyCode: SendVerifyCodeUseCase
    private let passwordHasher: PasswordHasher
    
    init(_ source: LocalDataSource, _ sendVerifyCode: SendVerifyCodeUseCase, _ passwordHasher: PasswordHasher) {
        self.source = source
        self.sendVerifyCode = sendVerifyCode
        self.passwordHasher = passwordHasher
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
            password: try await passwordHasher.hash(password),
            verifyCode: try HMACSHA256.computeHash(verifyCode).base64EncodedString(),
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
        
        let hash = try HMACSHA256.computeHash(verifyCode).base64EncodedString()
        guard user.verifyCode == hash else {
            user.verifyAttempts += 1
            try source.updateUser(user)
            throw VerifyError.invalidCode
        }
        
        user.verifyCode = ""
        user.verifyAttempts += 1
        try source.updateUser(user)
    }
    
    func login(mail: String, password: String) async throws -> TokenPair {
        guard let user = try source.getUser(mail: mail) else { throw LoginError.invalidMail }
        guard try await passwordHasher.verify(password: password, hash: user.password) else { throw LoginError.invalidPassword }
        guard user.verified else { throw LoginError.invalidUser }
        
        return try publishTokenPair(userId: user.id)
    }
    
    private func publishTokenPair(userId: UUID) throws -> TokenPair {
        let accessToken = try JWT.encode(sub: userId.uuidString, exp: Date(timeIntervalSinceNow: accessTokenExpireSeconds))
        let refreshToken = try JWT.encode(sub: publishRefreshToken(userId: userId), exp: Date(timeIntervalSinceNow: refreshTokenExpireSeconds))
        return TokenPair(accessToken: accessToken, refreshToken: refreshToken)
    }
    
    private func publishRefreshToken(userId: UUID) throws -> String {
        guard var user = try source.getUser(id: userId) else { throw LoginError.invalidUser }
        
        let token = try SecureRandomBytes.generate(length: 64).base64EncodedString()
        
        user.refreshToken = token
        try source.updateUser(user)
        
        return "\(user.id.uuidString)$\(token)"
    }
    
    func verifyLogin(token: String) -> Bool {
        guard let id = try? JWT.decode(token) else { return false }
        guard let uuid = UUID(uuidString: id) else { return false }
        guard let user = try? source.getUser(id: uuid) else { return false }
        guard user.verified else { return false }
        
        return true
    }
    
    func refresh(token: String) throws -> TokenPair {
        let refreshToken = try JWT.decode(token)
        let parts = refreshToken.split(separator: "$")
        let userId = parts[0]
        let token = parts[1]
        
        guard let uuid = UUID(uuidString: String(userId)) else { throw RefreshError.invalidToken }
        guard let user = try source.getUser(id: uuid) else { throw RefreshError.invalidToken }
        guard user.refreshToken == token else { throw RefreshError.invalidToken }
        
        return try publishTokenPair(userId: user.id)
    }
}
