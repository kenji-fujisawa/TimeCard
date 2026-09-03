//
//  LoginViewModel.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2026/08/31.
//

import Foundation

@Observable
class LoginViewModel {
    enum State {
        case login
        case register
        case verify
    }
    
    var state: State = .login
    var mail: String = ""
    var password: String = ""
    var passwordConfirm: String = ""
    var verifyCode: String = ""
    var error: String? = nil
    var isLoggedIn: Bool
    
    @ObservationIgnored private let repository: AuthRepository
    
    init(_ repository: AuthRepository) {
        self.repository = repository
        self.isLoggedIn = repository.isLoggedIn()
        
        repository.onLogout {
            self.isLoggedIn = false
        }
    }
    
    func login() {
        guard !mail.isEmpty else {
            error = "メールアドレスを入力してください"
            return
        }
        
        guard !password.isEmpty else {
            error = "パスワードを入力してください"
            return
        }
        
        Task {
            self.error = nil
            
            do {
                try await repository.login(mail: mail, password: password)
                mail = ""
                password = ""
                isLoggedIn = repository.isLoggedIn()
            } catch {
                self.error = "メールアドレス、またはパスワードが間違っています"
            }
        }
    }
    
    func register() {
        guard !mail.isEmpty else {
            error = "メールアドレスを入力してください"
            return
        }
        
        guard !password.isEmpty else {
            error = "パスワードを入力してください"
            return
        }
        
        guard password == passwordConfirm else {
            error = "パスワードが一致していません"
            return
        }
        
        Task {
            self.error = nil
            
            do {
                try await repository.register(mail: mail, password: password)
                state = .verify
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    func verify() {
        guard !mail.isEmpty else {
            error = "メールアドレスを入力してください"
            return
        }
        
        guard !verifyCode.isEmpty else {
            error = "認証コードを入力してください"
            return
        }
        
        Task {
            self.error = nil
            
            do {
                try await repository.verify(mail: mail, verifyCode: verifyCode)
                state = .login
                mail = ""
                password = ""
                passwordConfirm = ""
                verifyCode = ""
                isLoggedIn = repository.isLoggedIn()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    func switchToRegister() {
        state = .register
        mail = ""
        password = ""
        error = nil
    }
    
    func switchToLogin() {
        state = .login
        mail = ""
        password = ""
        passwordConfirm = ""
        error = nil
    }
}
