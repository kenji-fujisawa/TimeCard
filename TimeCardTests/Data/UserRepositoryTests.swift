//
//  UserRepositoryTests.swift
//  TimeCardTests
//
//  Created by uhimania on 2026/04/28.
//

import Foundation
import Testing

@testable import TimeCard

struct UserRepositoryTests {

    @Test func testRegister() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let mail = "aaa@test.com"
        let pass = "aaa"
        try await repository.register(mail: mail, password: pass)
        #expect(source.inserted.count == 1)
        #expect(source.inserted[0].mail == mail)
        #expect(try await passwordHasher.verify(password: pass, hash: source.inserted[0].password))
        #expect(source.inserted[0].verifyCode.isEmpty == false)
        #expect(source.inserted[0].verifyCodeExpires > .now)
        #expect(source.inserted[0].verifyCodeExpires < Date(timeIntervalSinceNow: 10 * 60))
        #expect(source.inserted[0].verifyAttempts == 0)
        #expect(sendVerifyCode.mail == mail)
        #expect(sendVerifyCode.verifyCode.isEmpty == false)
        #expect(try HMACSHA256.computeHash(sendVerifyCode.verifyCode).base64EncodedString() == source.inserted[0].verifyCode)
    }
    
    @Test func testRegister_duplicate() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let mail = "aaa@test.com"
        let pass = "aaa"
        source.user = User(mail: mail, password: pass)
        
        await #expect(throws: DefaultUserRepository.RegisterError.duplicateMail) {
            try await repository.register(mail: mail, password: pass)
        }
        
        #expect(source.inserted.count == 0)
        #expect(sendVerifyCode.mail.isEmpty)
        #expect(sendVerifyCode.verifyCode.isEmpty)
    }
    
    @Test func testRegister_emptyMail() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let mail = ""
        let pass = "aaa"
        
        await #expect(throws: DefaultUserRepository.RegisterError.invalidMail) {
            try await repository.register(mail: mail, password: pass)
        }
        
        #expect(source.inserted.count == 0)
        #expect(sendVerifyCode.mail.isEmpty)
        #expect(sendVerifyCode.verifyCode.isEmpty)
    }
    
    @Test func testRegister_invalidMail() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let mail = "aaa"
        let pass = "aaa"
        
        await #expect(throws: DefaultUserRepository.RegisterError.invalidMail) {
            try await repository.register(mail: mail, password: pass)
        }
        
        #expect(source.inserted.count == 0)
        #expect(sendVerifyCode.mail.isEmpty)
        #expect(sendVerifyCode.verifyCode.isEmpty)
    }
    
    @Test func testRegister_invalidPassword() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let mail = "aaa@test.com"
        let pass = ""
        
        await #expect(throws: DefaultUserRepository.RegisterError.invalidPassword) {
            try await repository.register(mail: mail, password: pass)
        }
        
        #expect(source.inserted.count == 0)
        #expect(sendVerifyCode.mail.isEmpty)
        #expect(sendVerifyCode.verifyCode.isEmpty)
    }
    
    @Test func testVerify() async throws {
        let source = FakeLocalDataSource()
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
        source.user = user
        
        let tokens = try repository.verify(mail: user.mail, verifyCode: verifyCode)
        #expect(source.updated.count == 2)
        #expect(source.updated[0].mail == user.mail)
        #expect(source.updated[0].password == user.password)
        #expect(source.updated[0].verifyCode == "")
        #expect(source.updated[0].verifyCodeExpires == user.verifyCodeExpires)
        #expect(source.updated[0].verifyAttempts == user.verifyAttempts + 1)
        
        source.user?.verifyCode = ""
        #expect(repository.verifyLogin(token: tokens.accessToken) == true)
        
        source.user?.refreshToken = source.updated[1].refreshToken
        let refresed = try repository.refresh(token: tokens.refreshToken)
        #expect(refresed.accessToken != tokens.accessToken)
        #expect(refresed.refreshToken != tokens.refreshToken)
    }
    
    @Test func testVerify_invalidMail() async throws {
        let source = FakeLocalDataSource()
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
        source.user = user
        
        #expect(throws: DefaultUserRepository.VerifyError.invalidMail) {
            try repository.verify(mail: "bbb@test.com", verifyCode: verifyCode)
        }
        
        #expect(source.updated.count == 0)
    }
    
    @Test func testVerify_invalidCode() async throws {
        let source = FakeLocalDataSource()
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
        source.user = user
        
        #expect(throws: DefaultUserRepository.VerifyError.invalidCode) {
            try repository.verify(mail: user.mail, verifyCode: "222")
        }
        
        #expect(source.updated.count == 1)
        #expect(source.updated[0].mail == user.mail)
        #expect(source.updated[0].password == user.password)
        #expect(source.updated[0].verifyCode == user.verifyCode)
        #expect(source.updated[0].verifyCodeExpires == user.verifyCodeExpires)
        #expect(source.updated[0].verifyAttempts == user.verifyAttempts + 1)
    }
    
    @Test func testVerify_expiredCode() async throws {
        let source = FakeLocalDataSource()
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
        source.user = user
        
        #expect(throws: DefaultUserRepository.VerifyError.expiredCode) {
            try repository.verify(mail: user.mail, verifyCode: verifyCode)
        }
        
        #expect(source.updated[0].mail == user.mail)
        #expect(source.updated[0].password == user.password)
        #expect(source.updated[0].verifyCode == user.verifyCode)
        #expect(source.updated[0].verifyCodeExpires == user.verifyCodeExpires)
        #expect(source.updated[0].verifyAttempts == user.verifyAttempts + 1)
    }
    
    @Test func testVerify_exceedAttempts() async throws {
        let source = FakeLocalDataSource()
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
        source.user = user
        
        #expect(throws: DefaultUserRepository.VerifyError.exceedAttempts) {
            try repository.verify(mail: user.mail, verifyCode: verifyCode)
        }
        
        #expect(source.updated[0].mail == user.mail)
        #expect(source.updated[0].password == user.password)
        #expect(source.updated[0].verifyCode == user.verifyCode)
        #expect(source.updated[0].verifyCodeExpires == user.verifyCodeExpires)
        #expect(source.updated[0].verifyAttempts == user.verifyAttempts + 1)
    }
    
    @Test func testLogin() async throws {
        let source = FakeLocalDataSource()
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
        source.user = user
        
        let tokens = try await repository.login(mail: user.mail, password: pass)
        #expect(source.updated.count == 2)
        #expect(source.updated[0].loginAttempts == 0)
        #expect(source.updated[0].lastAttempt == nil)
        #expect(source.updated[0].locked == nil)
        
        #expect(try JWT.decode(tokens.accessToken) == user.id.uuidString)
        #expect(repository.verifyLogin(token: tokens.accessToken) == true)
        
        let code = try JWT.decode(tokens.refreshToken)
        let parts = code.split(separator: "$")
        #expect(parts[0] == user.id.uuidString)
        #expect(!parts[1].isEmpty)
        #expect(source.updated[1].refreshToken == parts[1])
        
        source.user?.refreshToken = source.updated[1].refreshToken
        let refresed = try repository.refresh(token: tokens.refreshToken)
        #expect(refresed.accessToken != tokens.accessToken)
        #expect(refresed.refreshToken != tokens.refreshToken)
    }
    
    @Test func testLogin_invalidMail() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let pass = "aaa"
        let user = User(
            mail: "aaa@test.com",
            password: try await passwordHasher.hash(pass)
        )
        source.user = user
        
        await #expect(throws: DefaultUserRepository.LoginError.invalidMail) {
            try await repository.login(mail: "bbb@test.com", password: pass)
        }
        
        #expect(source.updated.count == 0)
    }
    
    @Test func testLogin_invalidPassword() async throws {
        let source = FakeLocalDataSource()
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
        source.user = user
        
        await #expect(throws: DefaultUserRepository.LoginError.invalidPassword) {
            try await repository.login(mail: user.mail, password: "bbb")
        }
        
        #expect(source.updated.count == 1)
        #expect(source.updated[0].loginAttempts == 4)
        #expect(source.updated[0].lastAttempt != lastAttempt)
        #expect(Date.now.equals(source.updated[0].lastAttempt ?? .distantPast))
        #expect(source.updated[0].locked == nil)
    }
    
    @Test func testLogin_invalidPassword_resetAttempt() async throws {
        let source = FakeLocalDataSource()
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
        source.user = user
        
        await #expect(throws: DefaultUserRepository.LoginError.invalidPassword) {
            try await repository.login(mail: user.mail, password: "bbb")
        }
        
        #expect(source.updated.count == 1)
        #expect(source.updated[0].loginAttempts == 1)
        #expect(Date.now.equals(source.updated[0].lastAttempt ?? .distantPast))
        #expect(source.updated[0].locked == nil)
    }
    
    @Test func testLogin_invalidPassword_lock() async throws {
        let source = FakeLocalDataSource()
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
        source.user = user
        
        await #expect(throws: DefaultUserRepository.LoginError.invalidPassword) {
            try await repository.login(mail: user.mail, password: "bbb")
        }
        
        #expect(source.updated.count == 1)
        #expect(source.updated[0].loginAttempts == 5)
        #expect(source.updated[0].lastAttempt != lastAttempt)
        #expect(Date.now.equals(source.updated[0].lastAttempt ?? .distantPast))
        #expect(Date.now.equals(source.updated[0].locked ?? .distantPast))
    }
    
    @Test func testLogin_locked() async throws {
        let source = FakeLocalDataSource()
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
        source.user = user
        
        await #expect(throws: DefaultUserRepository.LoginError.accountLocked) {
            try await repository.login(mail: user.mail, password: pass)
        }
        
        #expect(source.updated.count == 0)
    }
    
    @Test func testLogin_invalidUser() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let pass = "aaa"
        let user = User(
            mail: "aaa@test.com",
            password: try await passwordHasher.hash(pass),
            verifyCode: "aaa"
        )
        source.user = user
        
        await #expect(throws: DefaultUserRepository.LoginError.invalidUser) {
            try await repository.login(mail: user.mail, password: pass)
        }
        
        #expect(source.updated.count == 0)
    }
    
    @Test func testVerifyLogin() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let user = User(
            mail: "aaa@test.com",
            password: "aaa"
        )
        source.user = user
        
        let token = try JWT.encode(sub: user.id.uuidString, exp: Date(timeIntervalSinceNow: 60))
        #expect(repository.verifyLogin(token: token) == true)
    }
    
    @Test func testVerifyLogin_expired() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let user = User(
            mail: "aaa@test.com",
            password: "aaa"
        )
        source.user = user
        
        let token = try JWT.encode(sub: user.id.uuidString, exp: .now)
        #expect(repository.verifyLogin(token: token) == false)
    }
    
    @Test func testVerifyLogin_notLoggedIn() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let user = User(
            mail: "aaa@test.com",
            password: "aaa"
        )
        
        let token = try JWT.encode(sub: user.id.uuidString, exp: Date(timeIntervalSinceNow: 60))
        #expect(repository.verifyLogin(token: token) == false)
    }
    
    @Test func testVerifyLogin_notVerified() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let user = User(
            mail: "aaa@test.com",
            password: "aaa",
            verifyCode: "aaa"
        )
        source.user = user
        
        let token = try JWT.encode(sub: user.id.uuidString, exp: Date(timeIntervalSinceNow: 60))
        #expect(repository.verifyLogin(token: token) == false)
    }
    
    @Test func testRefresh() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let token = "aaaaa"
        let user = User(
            mail: "aaa@test.com",
            password: "aaa",
            refreshToken: token
        )
        source.user = user
        
        let refreshToken = try JWT.encode(sub: "\(user.id.uuidString)$\(token)", exp: Date(timeIntervalSinceNow: 60))
        let tokens = try repository.refresh(token: refreshToken)
        #expect(tokens.refreshToken != refreshToken)
        #expect(repository.verifyLogin(token: tokens.accessToken) == true)
        
        #expect(source.updated.count == 1)
        
        source.user?.refreshToken = source.updated[0].refreshToken
        let refreshed = try repository.refresh(token: tokens.refreshToken)
        #expect(refreshed.accessToken != tokens.accessToken)
        #expect(refreshed.refreshToken != tokens.refreshToken)
    }
    
    @Test func testRefresh_expired() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let token = "aaaaa"
        let user = User(
            mail: "aaa@test.com",
            password: "aaa",
            refreshToken: token
        )
        source.user = user
        
        let refreshToken = try JWT.encode(sub: "\(user.id.uuidString)$\(token)", exp: .now)
        #expect(throws: JWT.JWTError.expired) {
            try repository.refresh(token: refreshToken)
        }
    }
    
    @Test func testRefresh_invalidUser() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let token = "aaaaa"
        let user = User(
            mail: "aaa@test.com",
            password: "aaa",
            refreshToken: token
        )
        source.user = user
        
        let refreshToken = try JWT.encode(sub: "test$\(token)", exp: Date(timeIntervalSinceNow: 60))
        #expect(throws: DefaultUserRepository.RefreshError.invalidToken) {
            try repository.refresh(token: refreshToken)
        }
    }
    
    @Test func testRefresh_invalidToken() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let passwordHasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, sendVerifyCode, passwordHasher)
        
        let token = "aaaaa"
        let user = User(
            mail: "aaa@test.com",
            password: "aaa",
            refreshToken: token
        )
        source.user = user
        
        let refreshToken = try JWT.encode(sub: "\(user.id.uuidString)$test", exp: Date(timeIntervalSinceNow: 60))
        #expect(throws: DefaultUserRepository.RefreshError.invalidToken) {
            try repository.refresh(token: refreshToken)
        }
    }
    
    class FakeLocalDataSource: LocalDataSource {
        func getTimeRecord(id: UUID) throws -> TimeCard.TimeRecord? { nil }
        func getBreakTime(id: UUID) throws -> TimeCard.TimeRecord.BreakTime? { nil }
        func getTimeRecords(year: Int, month: Int) throws -> [TimeCard.TimeRecord] { [] }
        func insertTimeRecord(_ record: TimeCard.TimeRecord) throws {}
        func updateTimeRecord(_ record: TimeCard.TimeRecord) throws {}
        func deleteTimeRecord(_ record: TimeCard.TimeRecord) throws {}
        func getUptimeRecords(year: Int, month: Int) throws -> [TimeCard.SystemUptimeRecord] { [] }
        func getUptimeRecord(id: UUID) throws -> TimeCard.SystemUptimeRecord? { nil }
        func insertUptimeRecord(_ record: TimeCard.SystemUptimeRecord) throws {}
        func updateUptimeRecord(_ record: TimeCard.SystemUptimeRecord) throws {}
        func deleteUptimeRecord(_ record: TimeCard.SystemUptimeRecord) throws {}
        
        var user: User? = nil
        func getUser(id: UUID) throws -> User? {
            user?.id == id ? user : nil
        }
        
        func getUser(mail: String) throws -> TimeCard.User? {
            user?.mail == mail ? user : nil
        }
        
        var inserted: [User] = []
        func insertUser(_ user: TimeCard.User) throws {
            inserted.append(user)
        }
        
        var updated: [User] = []
        func updateUser(_ user: TimeCard.User) throws {
            updated.append(user)
        }
        
        func deleteUser(_ user: TimeCard.User) throws {}
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
