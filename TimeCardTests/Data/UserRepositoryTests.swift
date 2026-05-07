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
        let hashPassword = HashPasswordUseCase()
        let repository = DefaultUserRepository(source, sendVerifyCode, hashPassword)
        
        let mail = "aaa@test.com"
        let pass = "aaa"
        try await repository.register(mail: mail, password: pass)
        #expect(source.inserted?.mail == mail)
        #expect(source.inserted?.password == (try hashPassword.execute(pass)))
        #expect(source.inserted?.verifyCode.isEmpty == false)
        #expect(source.inserted?.verifyCodeExpires ?? .distantPast > .now)
        #expect(source.inserted?.verifyCodeExpires ?? .distantFuture < Date(timeIntervalSinceNow: 10 * 60))
        #expect(source.inserted?.verifyAttempts == 0)
        #expect(sendVerifyCode.mail == mail)
        #expect(sendVerifyCode.verifyCode.isEmpty == false)
        #expect(try hashPassword.execute(sendVerifyCode.verifyCode) == source.inserted?.verifyCode)
    }
    
    @Test func testRegister_duplicate() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let hashPassword = HashPasswordUseCase()
        let repository = DefaultUserRepository(source, sendVerifyCode, hashPassword)
        
        let mail = "aaa@test.com"
        let pass = "aaa"
        source.user = User(mail: mail, password: pass)
        
        await #expect(throws: DefaultUserRepository.RegisterError.duplicateMail) {
            try await repository.register(mail: mail, password: pass)
        }
        
        #expect(source.inserted == nil)
        #expect(sendVerifyCode.mail.isEmpty)
        #expect(sendVerifyCode.verifyCode.isEmpty)
    }
    
    @Test func testRegister_emptyMail() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let hashPassword = HashPasswordUseCase()
        let repository = DefaultUserRepository(source, sendVerifyCode, hashPassword)
        
        let mail = ""
        let pass = "aaa"
        
        await #expect(throws: DefaultUserRepository.RegisterError.invalidMail) {
            try await repository.register(mail: mail, password: pass)
        }
        
        #expect(source.inserted == nil)
        #expect(sendVerifyCode.mail.isEmpty)
        #expect(sendVerifyCode.verifyCode.isEmpty)
    }
    
    @Test func testRegister_invalidMail() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let hashPassword = HashPasswordUseCase()
        let repository = DefaultUserRepository(source, sendVerifyCode, hashPassword)
        
        let mail = "aaa"
        let pass = "aaa"
        
        await #expect(throws: DefaultUserRepository.RegisterError.invalidMail) {
            try await repository.register(mail: mail, password: pass)
        }
        
        #expect(source.inserted == nil)
        #expect(sendVerifyCode.mail.isEmpty)
        #expect(sendVerifyCode.verifyCode.isEmpty)
    }
    
    @Test func testRegister_invalidPassword() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let hashPassword = HashPasswordUseCase()
        let repository = DefaultUserRepository(source, sendVerifyCode, hashPassword)
        
        let mail = "aaa@test.com"
        let pass = ""
        
        await #expect(throws: DefaultUserRepository.RegisterError.invalidPassword) {
            try await repository.register(mail: mail, password: pass)
        }
        
        #expect(source.inserted == nil)
        #expect(sendVerifyCode.mail.isEmpty)
        #expect(sendVerifyCode.verifyCode.isEmpty)
    }
    
    @Test func testVerify() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let hashPassword = HashPasswordUseCase()
        let repository = DefaultUserRepository(source, sendVerifyCode, hashPassword)
        
        let verifyCode = "111"
        let user = User(
            mail: "aaa@test.com",
            password: "aaa",
            verifyCode: try hashPassword.execute(verifyCode),
            verifyCodeExpires: Date(timeIntervalSinceNow: 10 * 60),
            verifyAttempts: 4
        )
        source.user = user
        
        try repository.verify(mail: user.mail, verifyCode: verifyCode)
        #expect(source.updated?.mail == user.mail)
        #expect(source.updated?.password == user.password)
        #expect(source.updated?.verifyCode == "")
        #expect(source.updated?.verifyCodeExpires == user.verifyCodeExpires)
        #expect(source.updated?.verifyAttempts == user.verifyAttempts + 1)
    }
    
    @Test func testVerify_invalidMail() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let hashPassword = HashPasswordUseCase()
        let repository = DefaultUserRepository(source, sendVerifyCode, hashPassword)
        
        let verifyCode = "111"
        let user = User(
            mail: "aaa@test.com",
            password: "aaa",
            verifyCode: try hashPassword.execute(verifyCode),
            verifyCodeExpires: Date(timeIntervalSinceNow: 10 * 60),
            verifyAttempts: 0
        )
        source.user = user
        
        #expect(throws: DefaultUserRepository.VerifyError.invalidMail) {
            try repository.verify(mail: "bbb@test.com", verifyCode: verifyCode)
        }
        
        #expect(source.updated == nil)
    }
    
    @Test func testVerify_invalidCode() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let hashPassword = HashPasswordUseCase()
        let repository = DefaultUserRepository(source, sendVerifyCode, hashPassword)
        
        let verifyCode = "111"
        let user = User(
            mail: "aaa@test.com",
            password: "aaa",
            verifyCode: try hashPassword.execute(verifyCode),
            verifyCodeExpires: Date(timeIntervalSinceNow: 10 * 60),
            verifyAttempts: 0
        )
        source.user = user
        
        #expect(throws: DefaultUserRepository.VerifyError.invalidCode) {
            try repository.verify(mail: user.mail, verifyCode: "222")
        }
        
        #expect(source.updated?.mail == user.mail)
        #expect(source.updated?.password == user.password)
        #expect(source.updated?.verifyCode == user.verifyCode)
        #expect(source.updated?.verifyCodeExpires == user.verifyCodeExpires)
        #expect(source.updated?.verifyAttempts == user.verifyAttempts + 1)
    }
    
    @Test func testVerify_expiredCode() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let hashPassword = HashPasswordUseCase()
        let repository = DefaultUserRepository(source, sendVerifyCode, hashPassword)
        
        let verifyCode = "111"
        let user = User(
            mail: "aaa@test.com",
            password: "aaa",
            verifyCode: try hashPassword.execute(verifyCode),
            verifyCodeExpires: Date(timeIntervalSinceNow: -10 * 60),
            verifyAttempts: 0
        )
        source.user = user
        
        #expect(throws: DefaultUserRepository.VerifyError.expiredCode) {
            try repository.verify(mail: user.mail, verifyCode: verifyCode)
        }
        
        #expect(source.updated?.mail == user.mail)
        #expect(source.updated?.password == user.password)
        #expect(source.updated?.verifyCode == user.verifyCode)
        #expect(source.updated?.verifyCodeExpires == user.verifyCodeExpires)
        #expect(source.updated?.verifyAttempts == user.verifyAttempts + 1)
    }
    
    @Test func testVerify_exceedAttempts() async throws {
        let source = FakeLocalDataSource()
        let sendVerifyCode = FakeSendVerifyCodeUseCase()
        let hashPassword = HashPasswordUseCase()
        let repository = DefaultUserRepository(source, sendVerifyCode, hashPassword)
        
        let verifyCode = "111"
        let user = User(
            mail: "aaa@test.com",
            password: "aaa",
            verifyCode: try hashPassword.execute(verifyCode),
            verifyCodeExpires: Date(timeIntervalSinceNow: 10 * 60),
            verifyAttempts: 5
        )
        source.user = user
        
        #expect(throws: DefaultUserRepository.VerifyError.exceedAttempts) {
            try repository.verify(mail: user.mail, verifyCode: verifyCode)
        }
        
        #expect(source.updated?.mail == user.mail)
        #expect(source.updated?.password == user.password)
        #expect(source.updated?.verifyCode == user.verifyCode)
        #expect(source.updated?.verifyCodeExpires == user.verifyCodeExpires)
        #expect(source.updated?.verifyAttempts == user.verifyAttempts + 1)
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
        func getUser(mail: String) throws -> TimeCard.User? {
            user?.mail == mail ? user : nil
        }
        
        var inserted: User? = nil
        func insertUser(_ user: TimeCard.User) throws {
            inserted = user
        }
        
        var updated: User? = nil
        func updateUser(_ user: TimeCard.User) throws {
            updated = user
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
}
