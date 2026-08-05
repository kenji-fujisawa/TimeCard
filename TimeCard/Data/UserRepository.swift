//
//  UserRepository.swift
//  TimeCard
//
//  Created by uhimania on 2026/04/28.
//

import Foundation
import OSLog

struct TokenPair: Encodable {
    let accessToken: String
    let refreshToken: String
}

protocol UserRepository {
    func register(mail: String, password: String) async throws
    func verify(mail: String, verifyCode: String) throws -> TokenPair
    func login(mail: String, password: String) async throws -> TokenPair
    func verifyLogin(token: String) -> Bool
    func refresh(token: String) throws -> TokenPair
    func purgeExpiredTokens() throws
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
        case accountLocked
    }
    
    enum RefreshError: Error {
        case invalidToken
        case expiredToken
        case usedToken
    }
    
    private let verifyCodeExpireSeconds: TimeInterval = 10 * 60
    private let verifyAttemptsLimit = 5
    private let accessTokenExpireSeconds: TimeInterval = 10 * 60
    private let refreshTokenExpireSeconds: TimeInterval = 30 * 24 * 60 * 60
    private let loginAttemptsLimit: Int = 5
    private let loginAttemptResetSeconds: TimeInterval = 30 * 60
    private let lockResetSeconds: TimeInterval = 60 * 60
    
    private let source: LocalDataSource
    private let verifyCodeSender: VerifyCodeSender
    private let passwordHasher: PasswordHasher
    #if DEBUG
    private let logger = Logger(subsystem: "TimeCard.Debug", category: "audit")
    #else
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeCard", category: "audit")
    #endif
    
    init(_ source: LocalDataSource, _ verifyCodeSender: VerifyCodeSender, _ passwordHasher: PasswordHasher) {
        self.source = source
        self.verifyCodeSender = verifyCodeSender
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
        
        logger.info("user registered : \(user.id.uuidString, privacy: .public)")
        
        try await verifyCodeSender.send(to: mail, verifyCode: verifyCode, expire: verifyCodeExpires)
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
    
    func verify(mail: String, verifyCode: String) throws -> TokenPair {
        guard var user = try source.getUser(mail: mail) else { throw VerifyError.invalidMail }
        
        guard user.verifyCodeExpires >= .now else {
            user.verifyAttempts += 1
            try source.updateUser(user)
            logger.error("verify failed, code expired : \(user.id.uuidString, privacy: .public)")
            throw VerifyError.expiredCode
        }
        
        guard user.verifyAttempts < verifyAttemptsLimit else {
            user.verifyAttempts += 1
            try source.updateUser(user)
            logger.error("verify failed, exceed attempts : \(user.id.uuidString, privacy: .public)")
            throw VerifyError.exceedAttempts
        }
        
        let hash = try HMACSHA256.computeHash(verifyCode).base64EncodedString()
        guard user.verifyCode == hash else {
            user.verifyAttempts += 1
            try source.updateUser(user)
            logger.error("verify failed, invalid code : \(user.id.uuidString, privacy: .public)")
            throw VerifyError.invalidCode
        }
        
        user.verifyCode = ""
        user.verifyAttempts += 1
        try source.updateUser(user)
        
        logger.info("user verified : \(user.id.uuidString, privacy: .public)")
        
        return try publishTokenPair(userId: user.id)
    }
    
    func login(mail: String, password: String) async throws -> TokenPair {
        guard var user = try source.getUser(mail: mail) else { throw LoginError.invalidMail }
        guard user.verified else { throw LoginError.invalidUser }
        
        if let locked = user.locked,
           locked.addingTimeInterval(lockResetSeconds) > .now {
            logger.error("login failed, locked account : \(user.id.uuidString, privacy: .public)")
            throw LoginError.accountLocked
        }
        
        if let attempt = user.lastAttempt,
           attempt.addingTimeInterval(loginAttemptResetSeconds) <= .now {
            user.loginAttempts = 0
        }
        
        guard try await passwordHasher.verify(password: password, hash: user.password) else {
            user.loginAttempts += 1
            user.lastAttempt = .now
            
            if user.loginAttempts >= loginAttemptsLimit {
                user.locked = .now
            }
            
            try source.updateUser(user)
            
            logger.error("login failed, invalid password : \(user.id.uuidString, privacy: .public)")
            
            throw LoginError.invalidPassword
        }
        
        user.loginAttempts = 0
        user.lastAttempt = nil
        user.locked = nil
        try source.updateUser(user)
        
        logger.info("user logged in : \(user.id.uuidString, privacy: .public)")
        
        return try publishTokenPair(userId: user.id)
    }
    
    private func publishTokenPair(userId: UUID) throws -> TokenPair {
        let accessToken = try JWT.encode(sub: userId.uuidString, exp: Date(timeIntervalSinceNow: accessTokenExpireSeconds))
        let refreshToken = try publishRefreshToken(userId: userId)
        return TokenPair(accessToken: accessToken, refreshToken: refreshToken)
    }
    
    private func publishRefreshToken(userId: UUID) throws -> String {
        guard var user = try source.getUser(id: userId) else { throw LoginError.invalidUser }
        
        let token = try SecureRandomBytes.generate(length: 64).base64EncodedString()
        let refreshToken = User.RefreshToken(
            token: try HMACSHA256.computeHash(token).base64EncodedString(),
            status: .valid,
            expire: Date(timeIntervalSinceNow: refreshTokenExpireSeconds)
        )
        user.refreshTokens.append(refreshToken)
        try source.updateUser(user)
        
        return token
    }
    
    func verifyLogin(token: String) -> Bool {
        guard let id = try? JWT.decode(token) else { return false }
        guard let uuid = UUID(uuidString: id) else { return false }
        guard let user = try? source.getUser(id: uuid) else { return false }
        guard user.verified else { return false }
        
        return true
    }
    
    func refresh(token: String) throws -> TokenPair {
        let token = try HMACSHA256.computeHash(token).base64EncodedString()
        guard let refreshToken = try source.getRefreshToken(token: token) else { throw RefreshError.invalidToken }
        guard refreshToken.expire > .now else { throw RefreshError.expiredToken }
        
        guard let userId = refreshToken.userId else { throw RefreshError.invalidToken }
        guard var user = try source.getUser(id: userId) else { throw RefreshError.invalidToken }
        
        guard refreshToken.status == .valid else {
            user.refreshTokens = user.refreshTokens.map {
                var copy = $0
                copy.status = .revoked
                return copy
            }
            try source.updateUser(user)
            
            logger.critical("refresh failed, used token : \(user.id.uuidString, privacy: .public)")
            
            throw RefreshError.usedToken
        }
        
        user.refreshTokens = user.refreshTokens.map {
            var copy = $0
            copy.status = $0.token == token ? .used : $0.status
            return copy
        }
        try source.updateUser(user)
        
        logger.info("token refreshed : \(user.id.uuidString, privacy: .public)")
        
        return try publishTokenPair(userId: userId)
    }
    
    func purgeExpiredTokens() throws {
        let users = try source.getUsers()
        for var user in users {
            var tokens = user.refreshTokens
            tokens.removeAll { $0.expire < .now }
            user.refreshTokens = tokens
            try source.updateUser(user)
        }
    }
}
