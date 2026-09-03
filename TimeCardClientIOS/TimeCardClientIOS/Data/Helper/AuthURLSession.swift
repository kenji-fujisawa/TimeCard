//
//  AuthURLSession.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2026/08/14.
//

import Foundation

protocol AuthURLSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

class DefaultAuthURLSession: AuthURLSession {
    private let repository: AuthRepository
    
    init(_ repository: AuthRepository) {
        self.repository = repository
    }
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let token = repository.getAccessToken()
        var req = request
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: req)
        if let res = response as? HTTPURLResponse,
           res.statusCode == 401 {
            try await repository.refresh()
            
            let token = repository.getAccessToken()
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            return try await URLSession.shared.data(for: req)
        }
        
        return (data, response)
    }
}
