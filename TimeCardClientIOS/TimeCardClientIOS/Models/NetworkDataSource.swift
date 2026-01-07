//
//  NetworkDataSource.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/12/31.
//

import Foundation

protocol NetworkDataSource {
    func getRecords(year: Int, month: Int) async throws -> [TimeRecord]
    func insertRecord(record: TimeRecord) async throws -> TimeRecord
    func updateRecord(record: TimeRecord) async throws -> TimeRecord
    func deleteRecord(record: TimeRecord) async throws
}

class DefaultNetworkDataSource: NetworkDataSource {
    struct NetworkError: Error {
        let status: Int?
    }
    
    func getRecords(year: Int, month: Int) async throws -> [TimeRecord] {
        var url = URL(string: "http://192.168.4.33:8080/timecard/records")
        url = url?.appending(queryItems: [.init(name: "year", value: String(year))])
        url = url?.appending(queryItems: [.init(name: "month", value: String(month))])
        guard let url = url else { throw NetworkError(status: nil) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse,
           response.statusCode != 200 {
            throw NetworkError(status: response.statusCode)
        }
        
        return try JSONDecoder().decode([TimeRecord].self, from: data)
    }
    
    func insertRecord(record: TimeRecord) async throws -> TimeRecord {
        let url = URL(string: "http://192.168.4.33:8080/timecard/records")
        guard let url = url else { throw NetworkError(status: nil) }
        
        let json = try JSONEncoder().encode(record)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = json
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse,
           response.statusCode != 200 {
            throw NetworkError(status: response.statusCode)
        }
        
        let records = try JSONDecoder().decode([TimeRecord].self, from: data)
        guard let record = records.first else {
            throw NetworkError(status: nil)
        }
        
        return record
    }
    
    func updateRecord(record: TimeRecord) async throws -> TimeRecord {
        var url = URL(string: "http://192.168.4.33:8080/timecard/records")
        url = url?.appending(path: record.id.uuidString)
        guard let url = url else { throw NetworkError(status: nil) }
        
        let json = try JSONEncoder().encode(record)
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.httpBody = json
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse,
           response.statusCode != 200 {
            throw NetworkError(status: response.statusCode)
        }
        
        let records = try? JSONDecoder().decode([TimeRecord].self, from: data)
        guard let record = records?.first else {
            throw NetworkError(status: nil)
        }
        
        return record
    }
    
    func deleteRecord(record: TimeRecord) async throws {
        var url = URL(string: "http://192.168.4.33:8080/timecard/records")
        url = url?.appendingPathComponent(record.id.uuidString)
        guard let url = url else { throw NetworkError(status: nil) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse,
           response.statusCode != 200 {
            throw NetworkError(status: response.statusCode)
        }
    }
}
