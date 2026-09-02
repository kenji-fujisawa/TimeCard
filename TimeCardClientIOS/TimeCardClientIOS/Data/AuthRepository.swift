//
//  AuthRepository.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2026/08/14.
//

import Foundation

protocol AuthRepository {
    func register(mail: String, password: String) async throws
    func verify(mail: String, verifyCode: String) async throws
    func login(mail: String, password: String) async throws
    func refresh() async throws
    func isLoggedIn() -> Bool
    func onLogout(_ callback: @escaping () -> Void)
    func getAccessToken() -> String
}

class DefaultAuthRepository: AuthRepository {
    private let networkSource: AuthNetworkDataSource
    private let secureSource: SecureDataSource
    private var onLogoutCallbacks: [() -> Void] = []
    
    init(_ networkSource: AuthNetworkDataSource, _ secureSource: SecureDataSource) {
        self.networkSource = networkSource
        self.secureSource = secureSource
    }
    
    func register(mail: String, password: String) async throws {
        try await networkSource.register(mail: mail, password: password)
    }
    
    func verify(mail: String, verifyCode: String) async throws {
        let (accessToken, refreshToken) = try await networkSource.verify(mail: mail, verifyCode: verifyCode)
        try secureSource.save(accessToken, forKey: Constants.accessTokenKey)
        try secureSource.save(refreshToken, forKey: Constants.refreshTokenKey)
    }
    
    func login(mail: String, password: String) async throws {
        let (accessToken, refreshToken) = try await networkSource.login(mail: mail, password: password)
        try secureSource.save(accessToken, forKey: Constants.accessTokenKey)
        try secureSource.save(refreshToken, forKey: Constants.refreshTokenKey)
    }
    
    func refresh() async throws {
        do {
            let token = try secureSource.load(forKey: Constants.refreshTokenKey)
            let (accessToken, refreshToken) = try await networkSource.refresh(token: token)
            try secureSource.save(accessToken, forKey: Constants.accessTokenKey)
            try secureSource.save(refreshToken, forKey: Constants.refreshTokenKey)
        } catch let error as DefaultAuthNetworkDataSource.NetworkError {
            try logout()
            throw error
        }
    }
    
    func isLoggedIn() -> Bool {
        guard let token = try? secureSource.load(forKey: Constants.accessTokenKey) else { return false }
        return !token.isEmpty
    }
    
    func onLogout(_ callback: @escaping () -> Void) {
        onLogoutCallbacks.append(callback)
    }
    
    private func logout() throws {
        try secureSource.remove(forKey: Constants.accessTokenKey)
        try secureSource.remove(forKey: Constants.refreshTokenKey)
        onLogoutCallbacks.forEach { $0() }
    }
    
    func getAccessToken() -> String {
        (try? secureSource.load(forKey: Constants.accessTokenKey)) ?? ""
    }
}
