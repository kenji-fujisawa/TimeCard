//
//  LoginView.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2026/08/31.
//

import SwiftUI

struct LoginView: View {
    let viewModel: LoginViewModel
    
    var body: some View {
        if viewModel.state == .login {
            LoginView(viewModel: viewModel)
        } else if viewModel.state == .register {
            RegisterView(viewModel: viewModel)
        } else if viewModel.state == .verify {
            VerifyView(viewModel: viewModel)
        }
    }
    
    private struct LoginView: View {
        @Bindable var viewModel: LoginViewModel
        
        var body: some View {
            GroupBox {
                TextField("メールアドレス", text: $viewModel.mail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                Divider()
                SecureField("パスワード", text: $viewModel.password)
                    .textContentType(.password)
            }
            .padding(.horizontal)
            
            if let error = viewModel.error {
                Text(error)
                    .foregroundStyle(.red)
            }
            
            Button("ログイン") {
                viewModel.login()
            }
            .buttonStyle(.borderedProminent)
            
            Button("ユーザー登録はこちら") {
                viewModel.switchToRegister()
            }
            .padding(.top)
        }
    }
    
    private struct RegisterView: View {
        @Bindable var viewModel: LoginViewModel
        
        var body: some View {
            GroupBox {
                TextField("メールアドレス", text: $viewModel.mail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                Divider()
                SecureField("パスワード", text: $viewModel.password)
                    .textContentType(.newPassword)
                Divider()
                SecureField("パスワード（確認用）", text: $viewModel.passwordConfirm)
                    .textContentType(.newPassword)
            }
            .padding(.horizontal)
            
            if let error = viewModel.error {
                Text(error)
                    .foregroundStyle(.red)
            }
            
            Button("登録") {
                viewModel.register()
            }
            .buttonStyle(.borderedProminent)
            
            Button("ログイン画面に戻る") {
                viewModel.switchToLogin()
            }
            .padding(.top)
        }
    }
    
    private struct VerifyView: View {
        @Bindable var viewModel: LoginViewModel
        
        var body: some View {
            Text("メールアドレスに届いた\n認証コードを入力してください")
                .multilineTextAlignment(.center)
            GroupBox {
                TextField("認証コード", text: $viewModel.verifyCode)
                    .textContentType(.oneTimeCode)
                    .keyboardType(.numberPad)
            }
            .padding(.horizontal)
            
            if let error = viewModel.error {
                Text(error)
                    .foregroundStyle(.red)
            }
            
            Button("認証") {
                viewModel.verify()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    let repository = FakeAuthRepository()
    let viewModel = LoginViewModel(repository)
    LoginView(viewModel: viewModel)
}

private class FakeAuthRepository: AuthRepository {
    func register(mail: String, password: String) async throws {}
    func verify(mail: String, verifyCode: String) async throws {}
    func login(mail: String, password: String) async throws {}
    func refresh() async throws {}
    func isLoggedIn() -> Bool { false }
    func onLogout(_ callback: @escaping () -> Void) {}
    func getAccessToken() -> String { "" }
}
