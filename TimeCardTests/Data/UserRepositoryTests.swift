//
//  UserRepositoryTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2026/04/28.
//

import Foundation
import SwiftData
import Testing

@testable import TimeCard

struct UserRepositoryTests {

    private let container: ModelContainer
    private let context: ModelContext
    
    init() throws {
        let schema = Schema(versionedSchema: TimeCardSchema_v4.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        self.container = try ModelContainer(for: schema, configurations: config)
        self.context = ModelContext(container)
    }
    
    @Test func testRegister() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let mail = "aaa@test.com"
        let pass = "aaa"
        try await repository.register(mail: mail, password: pass)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].mail == mail)
        #expect(try await passwordHasher.verify(password: pass, hash: results[0].password) == true)
        #expect(results[0].verifyCode.isEmpty == false)
        #expect(results[0].verifyCodeExpires.equals(Date(timeIntervalSinceNow: 10 * 60)))
        #expect(results[0].verifyAttempts == 0)
        #expect(results[0].loginAttempts == 0)
        #expect(results[0].lastAttempt == nil)
        #expect(results[0].locked == nil)
        #expect(results[0].refreshTokens.count == 0)
        
        #expect(sendVerifyCode.mail == mail)
        #expect(sendVerifyCode.verifyCode.isEmpty == false)
        #expect(try HMACSHA256.computeHash(sendVerifyCode.verifyCode).base64EncodedString() == results[0].verifyCode)
    }
    
    @Test func testRegister_duplicate() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let mail = "aaa@test.com"
        let pass = "aaa"
        let user = User(mail: mail, password: pass)
        context.insert(user.asLocal())
        
        await #expect(throws: DefaultUserRepository.RegisterError.duplicateMail) {
            try await repository.register(mail: mail, password: pass)
        }
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].mail == mail)
        #expect(results[0].password == pass)
        #expect(results[0].verifyCode == "")
        #expect(results[0].verifyCodeExpires.equals(.now))
        #expect(results[0].verifyAttempts == 0)
        #expect(results[0].loginAttempts == 0)
        #expect(results[0].lastAttempt == nil)
        #expect(results[0].locked == nil)
        #expect(results[0].refreshTokens.count == 0)
        
        #expect(sendVerifyCode.mail.isEmpty)
        #expect(sendVerifyCode.verifyCode.isEmpty)
    }
    
    @Test func testRegister_emptyMail() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let mail = ""
        let pass = "aaa"
        
        await #expect(throws: DefaultUserRepository.RegisterError.invalidMail) {
            try await repository.register(mail: mail, password: pass)
        }
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 0)
        
        #expect(sendVerifyCode.mail.isEmpty)
        #expect(sendVerifyCode.verifyCode.isEmpty)
    }
    
    @Test func testRegister_invalidMail() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let mail = "aaa"
        let pass = "aaa"
        
        await #expect(throws: DefaultUserRepository.RegisterError.invalidMail) {
            try await repository.register(mail: mail, password: pass)
        }
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 0)
        
        #expect(sendVerifyCode.mail.isEmpty)
        #expect(sendVerifyCode.verifyCode.isEmpty)
    }
    
    @Test func testRegister_invalidPassword() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let mail = "aaa@test.com"
        let pass = ""
        
        await #expect(throws: DefaultUserRepository.RegisterError.invalidPassword) {
            try await repository.register(mail: mail, password: pass)
        }
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 0)
        
        #expect(sendVerifyCode.mail.isEmpty)
        #expect(sendVerifyCode.verifyCode.isEmpty)
    }
    
    @Test func testVerify() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let verifyCode = "111"
        let user = User(
            mail: "aaa@test.com",
            password: "aaa",
            verifyCode: try HMACSHA256.computeHash(verifyCode).base64EncodedString(),
            verifyCodeExpires: Date(timeIntervalSinceNow: 10 * 60),
            verifyAttempts: 4
        )
        context.insert(user.asLocal())
        
        let tokens = try repository.verify(mail: user.mail, verifyCode: verifyCode)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].id == user.id)
        #expect(results[0].mail == user.mail)
        #expect(results[0].password == user.password)
        #expect(results[0].verifyCode == "")
        #expect(results[0].verifyCodeExpires == user.verifyCodeExpires)
        #expect(results[0].verifyAttempts == user.verifyAttempts + 1)
        #expect(results[0].loginAttempts == 0)
        #expect(results[0].lastAttempt == nil)
        #expect(results[0].locked == nil)
        #expect(results[0].refreshTokens.count == 1)
        
        #expect(repository.verifyLogin(token: tokens.accessToken) == true)
        
        let refresed = try repository.refresh(token: tokens.refreshToken)
        #expect(refresed.accessToken != tokens.accessToken)
        #expect(refresed.refreshToken != tokens.refreshToken)
    }
    
    @Test func testVerify_invalidMail() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let verifyCode = "111"
        let user = User(
            mail: "aaa@test.com",
            password: "aaa",
            verifyCode: try HMACSHA256.computeHash(verifyCode).base64EncodedString(),
            verifyCodeExpires: Date(timeIntervalSinceNow: 10 * 60),
            verifyAttempts: 0
        )
        context.insert(user.asLocal())
        
        #expect(throws: DefaultUserRepository.VerifyError.invalidMail) {
            try repository.verify(mail: "bbb@test.com", verifyCode: verifyCode)
        }
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor).map { $0.asUser() }
        #expect(results.count == 1)
        #expect(results[0] == user)
    }
    
    @Test func testVerify_invalidCode() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let verifyCode = "111"
        let user = User(
            mail: "aaa@test.com",
            password: "aaa",
            verifyCode: try HMACSHA256.computeHash(verifyCode).base64EncodedString(),
            verifyCodeExpires: Date(timeIntervalSinceNow: 10 * 60),
            verifyAttempts: 0
        )
        context.insert(user.asLocal())
        
        #expect(throws: DefaultUserRepository.VerifyError.invalidCode) {
            try repository.verify(mail: user.mail, verifyCode: "222")
        }
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].id == user.id)
        #expect(results[0].mail == user.mail)
        #expect(results[0].password == user.password)
        #expect(results[0].verifyCode == user.verifyCode)
        #expect(results[0].verifyCodeExpires == user.verifyCodeExpires)
        #expect(results[0].verifyAttempts == user.verifyAttempts + 1)
        #expect(results[0].loginAttempts == user.loginAttempts)
        #expect(results[0].lastAttempt == user.lastAttempt)
        #expect(results[0].locked == user.locked)
        #expect(results[0].refreshTokens.count == user.refreshTokens.count)
    }
    
    @Test func testVerify_expiredCode() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let verifyCode = "111"
        let user = User(
            mail: "aaa@test.com",
            password: "aaa",
            verifyCode: try HMACSHA256.computeHash(verifyCode).base64EncodedString(),
            verifyCodeExpires: Date(timeIntervalSinceNow: -10 * 60),
            verifyAttempts: 0
        )
        context.insert(user.asLocal())
        
        #expect(throws: DefaultUserRepository.VerifyError.expiredCode) {
            try repository.verify(mail: user.mail, verifyCode: verifyCode)
        }
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].id == user.id)
        #expect(results[0].mail == user.mail)
        #expect(results[0].password == user.password)
        #expect(results[0].verifyCode == user.verifyCode)
        #expect(results[0].verifyCodeExpires == user.verifyCodeExpires)
        #expect(results[0].verifyAttempts == user.verifyAttempts + 1)
        #expect(results[0].loginAttempts == user.loginAttempts)
        #expect(results[0].lastAttempt == user.lastAttempt)
        #expect(results[0].locked == user.locked)
        #expect(results[0].refreshTokens.count == user.refreshTokens.count)
    }
    
    @Test func testVerify_exceedAttempts() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let verifyCode = "111"
        let user = User(
            mail: "aaa@test.com",
            password: "aaa",
            verifyCode: try HMACSHA256.computeHash(verifyCode).base64EncodedString(),
            verifyCodeExpires: Date(timeIntervalSinceNow: 10 * 60),
            verifyAttempts: 5
        )
        context.insert(user.asLocal())
        
        #expect(throws: DefaultUserRepository.VerifyError.exceedAttempts) {
            try repository.verify(mail: user.mail, verifyCode: verifyCode)
        }
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].id == user.id)
        #expect(results[0].mail == user.mail)
        #expect(results[0].password == user.password)
        #expect(results[0].verifyCode == user.verifyCode)
        #expect(results[0].verifyCodeExpires == user.verifyCodeExpires)
        #expect(results[0].verifyAttempts == user.verifyAttempts + 1)
        #expect(results[0].loginAttempts == user.loginAttempts)
        #expect(results[0].lastAttempt == user.lastAttempt)
        #expect(results[0].locked == user.locked)
        #expect(results[0].refreshTokens.count == user.refreshTokens.count)
    }
    
    @Test func testLogin() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let pass = "aaa"
        let user = User(
            mail: "aaa@test.com",
            password: try await passwordHasher.hash(pass),
            loginAttempts: 3,
            lastAttempt: .now,
            locked: Date(timeIntervalSinceNow: -24 * 60 * 60)
        )
        context.insert(user.asLocal())
        
        let tokens = try await repository.login(mail: user.mail, password: pass)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].id == user.id)
        #expect(results[0].mail == user.mail)
        #expect(results[0].password == user.password)
        #expect(results[0].verifyCode == user.verifyCode)
        #expect(results[0].verifyCodeExpires == user.verifyCodeExpires)
        #expect(results[0].verifyAttempts == user.verifyAttempts)
        #expect(results[0].loginAttempts == 0)
        #expect(results[0].lastAttempt == nil)
        #expect(results[0].locked == nil)
        #expect(results[0].refreshTokens.count == 1)
        
        #expect(try JWT.decode(tokens.accessToken) == user.id.uuidString)
        #expect(repository.verifyLogin(token: tokens.accessToken) == true)
        
        let token = try HMACSHA256.computeHash(tokens.refreshToken).base64EncodedString()
        #expect(results[0].refreshTokens[0].token == token)
        #expect(results[0].refreshTokens[0].expire.equals(Date(timeIntervalSinceNow: 30 * 24 * 60 * 60)))
        
        let refresed = try repository.refresh(token: tokens.refreshToken)
        #expect(refresed.accessToken != tokens.accessToken)
        #expect(refresed.refreshToken != tokens.refreshToken)
    }
    
    @Test func testLogin_multiDevice() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let pass = "aaa"
        let user = User(
            mail: "aaa@test.com",
            password: try await passwordHasher.hash(pass),
            loginAttempts: 3,
            lastAttempt: .now,
            locked: Date(timeIntervalSinceNow: -24 * 60 * 60)
        )
        context.insert(user.asLocal())
        
        let tokens = try await repository.login(mail: user.mail, password: pass)
        
        let descriptor = FetchDescriptor<LocalUser>()
        var results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].refreshTokens.count == 1)
        
        let tokens2 = try await repository.login(mail: user.mail, password: pass)
        
        results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].refreshTokens.count == 2)
        
        let token = try HMACSHA256.computeHash(tokens.refreshToken).base64EncodedString()
        let token2 = try HMACSHA256.computeHash(tokens2.refreshToken).base64EncodedString()
        #expect(results[0].refreshTokens.contains { $0.token == token })
        #expect(results[0].refreshTokens.contains { $0.token == token2 })
        
        #expect(tokens.accessToken != tokens2.accessToken)
        #expect(tokens.refreshToken != tokens2.refreshToken)
    }
    
    @Test func testLogin_invalidMail() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let pass = "aaa"
        let user = User(
            mail: "aaa@test.com",
            password: try await passwordHasher.hash(pass)
        )
        context.insert(user.asLocal())
        
        await #expect(throws: DefaultUserRepository.LoginError.invalidMail) {
            try await repository.login(mail: "bbb@test.com", password: pass)
        }
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor).map { $0.asUser() }
        #expect(results.count == 1)
        #expect(results[0] == user)
    }
    
    @Test func testLogin_invalidPassword() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let pass = "aaa"
        let lastAttempt = Date.now
        let user = User(
            mail: "aaa@test.com",
            password: try await passwordHasher.hash(pass),
            loginAttempts: 3,
            lastAttempt: lastAttempt,
            locked: nil
        )
        context.insert(user.asLocal())
        
        await #expect(throws: DefaultUserRepository.LoginError.invalidPassword) {
            try await repository.login(mail: user.mail, password: "bbb")
        }
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].id == user.id)
        #expect(results[0].mail == user.mail)
        #expect(results[0].password == user.password)
        #expect(results[0].verifyCode == user.verifyCode)
        #expect(results[0].verifyCodeExpires == user.verifyCodeExpires)
        #expect(results[0].verifyAttempts == user.verifyAttempts)
        #expect(results[0].loginAttempts == 4)
        #expect(results[0].lastAttempt != lastAttempt)
        #expect(Date.now.equals(results[0].lastAttempt ?? .distantPast))
        #expect(results[0].locked == nil)
        #expect(results[0].refreshTokens.count == user.refreshTokens.count)
    }
    
    @Test func testLogin_invalidPassword_resetAttempt() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let pass = "aaa"
        let user = User(
            mail: "aaa@test.com",
            password: try await passwordHasher.hash(pass),
            loginAttempts: 3,
            lastAttempt: Date(timeIntervalSinceNow: -24 * 60 * 60),
            locked: nil
        )
        context.insert(user.asLocal())
        
        await #expect(throws: DefaultUserRepository.LoginError.invalidPassword) {
            try await repository.login(mail: user.mail, password: "bbb")
        }
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].id == user.id)
        #expect(results[0].mail == user.mail)
        #expect(results[0].password == user.password)
        #expect(results[0].verifyCode == user.verifyCode)
        #expect(results[0].verifyCodeExpires == user.verifyCodeExpires)
        #expect(results[0].verifyAttempts == user.verifyAttempts)
        #expect(results[0].loginAttempts == 1)
        #expect(Date.now.equals(results[0].lastAttempt ?? .distantPast))
        #expect(results[0].locked == nil)
        #expect(results[0].refreshTokens.count == user.refreshTokens.count)
    }
    
    @Test func testLogin_invalidPassword_lock() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let pass = "aaa"
        let lastAttempt = Date.now
        let user = User(
            mail: "aaa@test.com",
            password: try await passwordHasher.hash(pass),
            loginAttempts: 4,
            lastAttempt: lastAttempt,
            locked: nil
        )
        context.insert(user.asLocal())
        
        await #expect(throws: DefaultUserRepository.LoginError.invalidPassword) {
            try await repository.login(mail: user.mail, password: "bbb")
        }
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].id == user.id)
        #expect(results[0].mail == user.mail)
        #expect(results[0].password == user.password)
        #expect(results[0].verifyCode == user.verifyCode)
        #expect(results[0].verifyCodeExpires == user.verifyCodeExpires)
        #expect(results[0].verifyAttempts == user.verifyAttempts)
        #expect(results[0].loginAttempts == 5)
        #expect(results[0].lastAttempt != lastAttempt)
        #expect(Date.now.equals(results[0].lastAttempt ?? .distantPast))
        #expect(Date.now.equals(results[0].locked ?? .distantPast))
        #expect(results[0].refreshTokens.count == user.refreshTokens.count)
    }
    
    @Test func testLogin_locked() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let pass = "aaa"
        let user = User(
            mail: "aaa@test.com",
            password: try await passwordHasher.hash(pass),
            loginAttempts: 3,
            lastAttempt: .now,
            locked: .now
        )
        context.insert(user.asLocal())
        
        await #expect(throws: DefaultUserRepository.LoginError.accountLocked) {
            try await repository.login(mail: user.mail, password: pass)
        }
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor).map { $0.asUser() }
        #expect(results.count == 1)
        #expect(results[0] == user)
    }
    
    @Test func testLogin_invalidUser() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let pass = "aaa"
        let user = User(
            mail: "aaa@test.com",
            password: try await passwordHasher.hash(pass),
            verifyCode: "aaa"
        )
        context.insert(user.asLocal())
        
        await #expect(throws: DefaultUserRepository.LoginError.invalidUser) {
            try await repository.login(mail: user.mail, password: pass)
        }
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor).map { $0.asUser() }
        #expect(results.count == 1)
        #expect(results[0] == user)
    }
    
    @Test func testVerifyLogin() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let user = User(
            mail: "aaa@test.com",
            password: "aaa"
        )
        context.insert(user.asLocal())
        
        let token = try JWT.encode(sub: user.id.uuidString, exp: Date(timeIntervalSinceNow: 60))
        #expect(repository.verifyLogin(token: token) == true)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor).map { $0.asUser() }
        #expect(results.count == 1)
        #expect(results[0] == user)
    }
    
    @Test func testVerifyLogin_expired() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let user = User(
            mail: "aaa@test.com",
            password: "aaa"
        )
        context.insert(user.asLocal())
        
        let token = try JWT.encode(sub: user.id.uuidString, exp: .now)
        #expect(repository.verifyLogin(token: token) == false)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor).map { $0.asUser() }
        #expect(results.count == 1)
        #expect(results[0] == user)
    }
    
    @Test func testVerifyLogin_notLoggedIn() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let user = User(
            mail: "aaa@test.com",
            password: "aaa"
        )
        
        let token = try JWT.encode(sub: user.id.uuidString, exp: Date(timeIntervalSinceNow: 60))
        #expect(repository.verifyLogin(token: token) == false)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 0)
    }
    
    @Test func testVerifyLogin_notVerified() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let user = User(
            mail: "aaa@test.com",
            password: "aaa",
            verifyCode: "aaa"
        )
        context.insert(user.asLocal())
        
        let token = try JWT.encode(sub: user.id.uuidString, exp: Date(timeIntervalSinceNow: 60))
        #expect(repository.verifyLogin(token: token) == false)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor).map { $0.asUser() }
        #expect(results.count == 1)
        #expect(results[0] == user)
    }
    
    @Test func testRefresh() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let token = "aaaaa"
        var user = User(
            mail: "aaa@test.com",
            password: "aaa"
        )
        user.refreshTokens.append(
            User.RefreshToken(
                token: try HMACSHA256.computeHash(token).base64EncodedString(),
                status: .valid,
                expire: Date(timeIntervalSinceNow: 60),
                userId: user.id
            )
        )
        user.refreshTokens.append(
            User.RefreshToken(
                token: try HMACSHA256.computeHash("bbbbb").base64EncodedString(),
                status: .used,
                expire: Date(timeIntervalSinceNow: 60),
                userId: user.id
            )
        )
        context.insert(user.asLocal())
        
        let tokens = try repository.refresh(token: token)
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].id == user.id)
        #expect(results[0].mail == user.mail)
        #expect(results[0].password == user.password)
        #expect(results[0].verifyCode == user.verifyCode)
        #expect(results[0].verifyCodeExpires == user.verifyCodeExpires)
        #expect(results[0].verifyAttempts == user.verifyAttempts)
        #expect(results[0].loginAttempts == user.loginAttempts)
        #expect(results[0].lastAttempt == user.lastAttempt)
        #expect(results[0].locked == user.locked)
        #expect(results[0].refreshTokens.count == 3)
        #expect(results[0].refreshTokens.contains { $0.token == user.refreshTokens[0].token } == true)
        #expect(results[0].refreshTokens.contains { $0.token == user.refreshTokens[1].token } == true)
        #expect(results[0].refreshTokens.first(where: { $0.token == user.refreshTokens[0].token })?.status == .used)
        #expect(results[0].refreshTokens.first(where: { $0.token == user.refreshTokens[1].token })?.status == .used)
        #expect(results[0].refreshTokens.first(where: { $0.token != user.refreshTokens[0].token && $0.token != user.refreshTokens[1].token })?.status == .valid)
        
        #expect(tokens.refreshToken != token)
        #expect(repository.verifyLogin(token: tokens.accessToken) == true)
        
        let refreshed = try repository.refresh(token: tokens.refreshToken)
        #expect(refreshed.accessToken != tokens.accessToken)
        #expect(refreshed.refreshToken != tokens.refreshToken)
    }
    
    @Test func testRefresh_expired() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let token = "aaaaa"
        var user = User(
            mail: "aaa@test.com",
            password: "aaa"
        )
        user.refreshTokens.append(
            User.RefreshToken(
                token: try HMACSHA256.computeHash(token).base64EncodedString(),
                status: .valid,
                expire: .now,
                userId: user.id
            )
        )
        context.insert(user.asLocal())
        
        #expect(throws: DefaultUserRepository.RefreshError.expiredToken) {
            try repository.refresh(token: token)
        }
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor).map { $0.asUser() }
        #expect(results.count == 1)
        #expect(results[0] == user)
    }
    
    @Test func testRefresh_invalidUser() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let token = "aaaaa"
        let user = User(
            mail: "aaa@test.com",
            password: "aaa",
        )
        let refreshToken = User.RefreshToken(
            token: try HMACSHA256.computeHash(token).base64EncodedString(),
            status: .valid,
            expire: Date(timeIntervalSinceNow: 60)
        )
        context.insert(user.asLocal())
        context.insert(refreshToken.asLocal())
        
        #expect(throws: DefaultUserRepository.RefreshError.invalidToken) {
            try repository.refresh(token: token)
        }
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor).map { $0.asUser() }
        #expect(results.count == 1)
        #expect(results[0] == user)
    }
    
    @Test func testRefresh_invalidToken() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let token = "aaaaa"
        var user = User(
            mail: "aaa@test.com",
            password: "aaa"
        )
        user.refreshTokens.append(
            User.RefreshToken(
                token: try HMACSHA256.computeHash(token).base64EncodedString(),
                status: .valid,
                expire: Date(timeIntervalSinceNow: 60),
                userId: user.id
            )
        )
        context.insert(user.asLocal())
        
        #expect(throws: DefaultUserRepository.RefreshError.invalidToken) {
            try repository.refresh(token: "bbbbb")
        }
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor).map { $0.asUser() }
        #expect(results.count == 1)
        #expect(results[0] == user)
    }
    
    @Test func testRefresh_usedToken() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let token = "aaaaa"
        var user = User(
            mail: "aaa@test.com",
            password: "aaa"
        )
        user.refreshTokens.append(
            User.RefreshToken(
                token: try HMACSHA256.computeHash(token).base64EncodedString(),
                status: .used,
                expire: Date(timeIntervalSinceNow: 60),
                userId: user.id
            )
        )
        user.refreshTokens.append(
            User.RefreshToken(
                token: try HMACSHA256.computeHash("bbbbb").base64EncodedString(),
                status: .valid,
                expire: Date(timeIntervalSinceNow: 60),
                userId: user.id
            )
        )
        context.insert(user.asLocal())
        
        #expect(throws: DefaultUserRepository.RefreshError.usedToken) {
            try repository.refresh(token: token)
        }
        
        let descriptor = FetchDescriptor<LocalUser>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].id == user.id)
        #expect(results[0].mail == user.mail)
        #expect(results[0].password == user.password)
        #expect(results[0].verifyCode == user.verifyCode)
        #expect(results[0].verifyCodeExpires == user.verifyCodeExpires)
        #expect(results[0].verifyAttempts == user.verifyAttempts)
        #expect(results[0].loginAttempts == user.loginAttempts)
        #expect(results[0].lastAttempt == user.lastAttempt)
        #expect(results[0].locked == user.locked)
        #expect(results[0].refreshTokens.count == 2)
        #expect(results[0].refreshTokens[0].status == .revoked)
        #expect(results[0].refreshTokens[1].status == .revoked)
    }
    
    @Test func testPurgeExpiredTokens() async throws {
        let source = DefaultLocalDataSource(context)
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let user1 = User(
            mail: "aaa@test.com",
            password: "aaa",
            refreshTokens: [
                User.RefreshToken(
                    token: "a1",
                    status: .valid,
                    expire: Date(timeIntervalSinceNow: 60)
                ),
                User.RefreshToken(
                    token: "a2",
                    status: .used,
                    expire: .now
                ),
                User.RefreshToken(
                    token: "a3",
                    status: .revoked,
                    expire: Date(timeIntervalSinceNow: 60)
                )
            ]
        )
        let user2 = User(
            mail: "bbb@test.com",
            password: "bbb",
            refreshTokens: [
                User.RefreshToken(
                    token: "b1",
                    status: .valid,
                    expire: .now
                ),
                User.RefreshToken(
                    token: "b2",
                    status: .revoked,
                    expire: Date(timeIntervalSinceNow: -60)
                )
            ]
        )
        context.insert(user1.asLocal())
        context.insert(user2.asLocal())
        
        try repository.purgeExpiredTokens()
        
        let descriptor = FetchDescriptor<LocalUser>(
            sortBy: [.init(\.mail)]
        )
        let results = try context.fetch(descriptor).map { $0.asUser() }
        #expect(results.count == 2)
        #expect(results[0].refreshTokens.count == 2)
        #expect(results[0].refreshTokens[0].token == user1.refreshTokens[0].token)
        #expect(results[0].refreshTokens[1].token == user1.refreshTokens[2].token)
        #expect(results[1].refreshTokens.count == 0)
    }
    
    class FakeSendVerifyCodeUseCase: SendVerifyCodeUseCase {
        var mail = ""
        var verifyCode = ""
        func execute(mail: String, verifyCode: String) async throws {
            self.mail = mail
            self.verifyCode = verifyCode
        }
    }
    
    class FakePasswordHasher: PasswordHasher {
        func hash(_ password: String) async throws -> String {
            try HMACSHA256.computeHash(password).base64EncodedString()
        }
        
        func verify(password: String, hash: String) async throws -> Bool {
            try HMACSHA256.computeHash(password).base64EncodedString() == hash
        }
    }
}

private extension Date {
    func equals(_ date: Date) -> Bool {
        abs(self.distance(to: date)) < 1
    }
}
