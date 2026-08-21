//
//  AuthNetworkDataSource.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2026/08/20.
//

import Foundation

protocol AuthNetworkDataSource {
    func register(mail: String, password: String) async throws
    func verify(mail: String, verifyCode: String) async throws -> (accessToken: String, refreshToken: String)
    func login(mail: String, password: String) async throws -> (accessToken: String, refreshToken: String)
    func refresh(token: String) async throws -> (accessToken: String, refreshToken: String)
}

class DefaultAuthNetworkDataSource: AuthNetworkDataSource {
    struct NetworkError: Error {
        let status: Int?
    }
    
    private let baseUrl: URL
    
    init(_ baseUrl: URL) {
        self.baseUrl = baseUrl
    }
    
    func register(mail: String, password: String) async throws {
        let url = baseUrl.appending(path: "timecard/auth/register")
        
        var json: [String: String] = [:]
        json["mail"] = mail
        json["password"] = password
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: json)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse,
           response.statusCode != 201 {
            throw NetworkError(status: response.statusCode)
        }
    }
    
    func verify(mail: String, verifyCode: String) async throws -> (accessToken: String, refreshToken: String) {
        let url = baseUrl.appending(path: "timecard/auth/verify")
        
        var json: [String: String] = [:]
        json["mail"] = mail
        json["verifyCode"] = verifyCode
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: json)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse,
           response.statusCode != 200 {
            throw NetworkError(status: response.statusCode)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let accessToken = json["accessToken"],
              let refreshToken = json["refreshToken"] else {
            throw NetworkError(status: 500)
        }
        
        return (accessToken, refreshToken)
    }
    
    func login(mail: String, password: String) async throws -> (accessToken: String, refreshToken: String) {
        let url = baseUrl.appending(path: "timecard/auth/login")
        
        var json: [String: String] = [:]
        json["mail"] = mail
        json["password"] = password
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: json)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse,
           response.statusCode != 200 {
            throw NetworkError(status: response.statusCode)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let accessToken = json["accessToken"],
              let refreshToken = json["refreshToken"] else {
            throw NetworkError(status: 500)
        }
        
        return (accessToken, refreshToken)
    }
    
    func refresh(token: String) async throws -> (accessToken: String, refreshToken: String) {
        let url = baseUrl.appending(path: "timecard/auth/refresh")
        
        var json: [String: String] = [:]
        json["refreshToken"] = token
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: json)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse,
           response.statusCode != 200 {
            throw NetworkError(status: response.statusCode)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let accessToken = json["accessToken"],
              let refreshToken = json["refreshToken"] else {
            throw NetworkError(status: 500)
        }
        
        return (accessToken, refreshToken)
    }
}
