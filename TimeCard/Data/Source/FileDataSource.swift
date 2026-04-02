//
//  FileDataSource.swift
//  TimeCard
//
//  Created by uhimania on 2026/04/02.
//

import Foundation

protocol FileDataSource {
    func getUptimeRecords() throws -> [SystemUptimeRecord]
    func saveUptimeRecords(_ records: [SystemUptimeRecord]) throws
    func removeUptimeRecords() throws
}

class DefaultFileDataSource: FileDataSource {
    private let url = FileManager.default.temporaryDirectory.appendingPathComponent("UptimeRecords.json")
    
    func getUptimeRecords() throws -> [SystemUptimeRecord] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return try JSONDecoder().decode([SystemUptimeRecord].self, from: data)
    }
    
    func saveUptimeRecords(_ records: [SystemUptimeRecord]) throws {
        let json = try JSONEncoder().encode(records)
        try json.write(to: url)
    }
    
    func removeUptimeRecords() throws {
        try FileManager.default.removeItem(at: url)
    }
}
