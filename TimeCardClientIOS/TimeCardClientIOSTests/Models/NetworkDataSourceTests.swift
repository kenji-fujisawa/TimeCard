//
//  NetworkDataSourceTests.swift
//  TimeCardClientIOSTests
//
//  Created by uhimania on 2025/12/31.
//

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import Testing

@testable import TimeCardClientIOS

class NetworkDataSourceTests {

    private let responseBody = """
        [
            {
                "id":"1B97D98D-A71E-4E57-B631-20F9AD492624",
                "year":2025,
                "month":12,
                "checkIn":786242897.725608,
                "checkOut":786277228.928412,
                "breakTimes":[
                    {
                        "id":"A92129DB-92B8-4057-A5CC-D965D9664B35",
                        "start":786252677.725608,
                        "end":786255737.725608
                    }
                ]
            },
            {
                "id":"4D1A3B51-D16F-486A-93FC-85C231DDACAD",
                "year":2025,
                "month":12,
                "checkIn":786328648.080071,
                "checkOut":786361916.853093,
                "breakTimes":[
                    {
                        "id":"B85CDC50-C796-4A9D-AD95-46FFD1D8EA13",
                        "start":786339206.024485,
                        "end":786342090.21777
                    }
                ]
            }
        ]
        """
    
    deinit {
        HTTPStubs.removeAllStubs()
    }
    
    @Test func testGetRecords_success() async throws {
        var request: URLRequest? = nil
        stub(condition: isHost("192.168.4.33")) { req in
            request = req
            
            return HTTPStubsResponse(data: self.responseBody.data(using: .utf8) ?? Data(), statusCode: 200, headers: nil)
        }
        
        let source = DefaultNetworkDataSource()
        let records = try await source.getRecords(year: 2025, month: 12)
        
        #expect(request?.url?.path() == "/timecard/records")
        #expect(request?.url?.query() == "year=2025&month=12")
        #expect(request?.httpMethod == "GET")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        #expect(records.count == 2)
        
        #expect(records[0].id.uuidString == "1B97D98D-A71E-4E57-B631-20F9AD492624")
        #expect(records[0].year == 2025)
        #expect(records[0].month == 12)
        #expect(formatter.string(for: records[0].checkIn) == "2025-12-01 09:48")
        #expect(formatter.string(for: records[0].checkOut) == "2025-12-01 19:20")
        #expect(records[0].breakTimes.count == 1)
        #expect(records[0].breakTimes[0].id.uuidString == "A92129DB-92B8-4057-A5CC-D965D9664B35")
        #expect(formatter.string(for: records[0].breakTimes[0].start) == "2025-12-01 12:31")
        #expect(formatter.string(for: records[0].breakTimes[0].end) == "2025-12-01 13:22")
        
        #expect(records[1].id.uuidString == "4D1A3B51-D16F-486A-93FC-85C231DDACAD")
        #expect(records[1].year == 2025)
        #expect(records[1].month == 12)
        #expect(formatter.string(for: records[1].checkIn) == "2025-12-02 09:37")
        #expect(formatter.string(for: records[1].checkOut) == "2025-12-02 18:51")
        #expect(records[1].breakTimes.count == 1)
        #expect(records[1].breakTimes[0].id.uuidString == "B85CDC50-C796-4A9D-AD95-46FFD1D8EA13")
        #expect(formatter.string(for: records[1].breakTimes[0].start) == "2025-12-02 12:33")
        #expect(formatter.string(for: records[1].breakTimes[0].end) == "2025-12-02 13:21")
    }
    
    @Test func testGetRecords_fail() async throws {
        stub(condition: isHost("192.168.4.33")) { _ in
            return HTTPStubsResponse(data: Data(), statusCode: 404, headers: nil)
        }
        
        let source = DefaultNetworkDataSource()
        await #expect(throws: DefaultNetworkDataSource.NetworkError.self) {
            try await source.getRecords(year: 2025, month: 12)
        }
    }
    
    @Test func testInsertRecords_success() async throws {
        var request: URLRequest? = nil
        var requestBody: Data? = nil
        stub(condition: isHost("192.168.4.33")) { req in
            request = req
            requestBody = req.ohhttpStubs_httpBody
            
            return HTTPStubsResponse(data: self.responseBody.data(using: .utf8) ?? Data(), statusCode: 200, headers: nil)
        }
        
        let source = DefaultNetworkDataSource()
        let record = TimeRecord(id: UUID(), year: Date.now.year, month: Date.now.month, checkIn: .now, checkOut: .now, breakTimes: [])
        let response = try await source.insertRecord(record: record)
        
        #expect(request?.url?.path() == "/timecard/records")
        #expect(request?.httpMethod == "POST")
        
        let rec = try? JSONDecoder().decode(TimeRecord.self, from: requestBody ?? Data())
        #expect(rec == record)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        #expect(response.id.uuidString == "1B97D98D-A71E-4E57-B631-20F9AD492624")
        #expect(response.year == 2025)
        #expect(response.month == 12)
        #expect(formatter.string(for: response.checkIn) == "2025-12-01 09:48")
        #expect(formatter.string(for: response.checkOut) == "2025-12-01 19:20")
        #expect(response.breakTimes.count == 1)
        #expect(response.breakTimes[0].id.uuidString == "A92129DB-92B8-4057-A5CC-D965D9664B35")
        #expect(formatter.string(for: response.breakTimes[0].start) == "2025-12-01 12:31")
        #expect(formatter.string(for: response.breakTimes[0].end) == "2025-12-01 13:22")
    }
    
    @Test func testInsertRecords_fail() async throws {
        stub(condition: isHost("192.168.4.33")) { _ in
            return HTTPStubsResponse(data: Data(), statusCode: 404, headers: nil)
        }
        
        let source = DefaultNetworkDataSource()
        let request = TimeRecord(id: UUID(), year: Date.now.year, month: Date.now.month, checkIn: .now, checkOut: .now, breakTimes: [])
        await #expect(throws: DefaultNetworkDataSource.NetworkError.self) {
            try await source.insertRecord(record: request)
        }
    }
    
    @Test func testUpdateRecords_success() async throws {
        var request: URLRequest? = nil
        var requestBody: Data? = nil
        stub(condition: isHost("192.168.4.33")) { req in
            request = req
            requestBody = req.ohhttpStubs_httpBody
            
            return HTTPStubsResponse(data: self.responseBody.data(using: .utf8) ?? Data(), statusCode: 200, headers: nil)
        }
        
        let source = DefaultNetworkDataSource()
        let record = TimeRecord(id: UUID(), year: Date.now.year, month: Date.now.month, checkIn: .now, checkOut: .now, breakTimes: [])
        let response = try await source.updateRecord(record: record)
        
        #expect(request?.url?.path() == "/timecard/records/\(record.id.uuidString)")
        #expect(request?.httpMethod == "PATCH")
        
        let rec = try? JSONDecoder().decode(TimeRecord.self, from: requestBody ?? Data())
        #expect(rec == record)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        #expect(response.id.uuidString == "1B97D98D-A71E-4E57-B631-20F9AD492624")
        #expect(response.year == 2025)
        #expect(response.month == 12)
        #expect(formatter.string(for: response.checkIn) == "2025-12-01 09:48")
        #expect(formatter.string(for: response.checkOut) == "2025-12-01 19:20")
        #expect(response.breakTimes.count == 1)
        #expect(response.breakTimes[0].id.uuidString == "A92129DB-92B8-4057-A5CC-D965D9664B35")
        #expect(formatter.string(for: response.breakTimes[0].start) == "2025-12-01 12:31")
        #expect(formatter.string(for: response.breakTimes[0].end) == "2025-12-01 13:22")
    }
    
    @Test func testUpdateRecords_fail() async throws {
        stub(condition: isHost("192.168.4.33")) { _ in
            return HTTPStubsResponse(data: Data(), statusCode: 404, headers: nil)
        }
        
        let source = DefaultNetworkDataSource()
        let request = TimeRecord(id: UUID(), year: Date.now.year, month: Date.now.month, checkIn: .now, checkOut: .now, breakTimes: [])
        await #expect(throws: DefaultNetworkDataSource.NetworkError.self) {
            try await source.updateRecord(record: request)
        }
    }
    
    @Test func testDeleteRecords_success() async throws {
        var request: URLRequest? = nil
        stub(condition: isHost("192.168.4.33")) { req in
            request = req
            
            return HTTPStubsResponse(data: self.responseBody.data(using: .utf8) ?? Data(), statusCode: 200, headers: nil)
        }
        
        let source = DefaultNetworkDataSource()
        let record = TimeRecord(id: UUID(), year: Date.now.year, month: Date.now.month, checkIn: .now, checkOut: .now, breakTimes: [])
        try await source.deleteRecord(record: record)
        
        #expect(request?.url?.path() == "/timecard/records/\(record.id.uuidString)")
        #expect(request?.httpMethod == "DELETE")
    }
    
    @Test func testDeleteRecords_fail() async throws {
        stub(condition: isHost("192.168.4.33")) { _ in
            return HTTPStubsResponse(data: Data(), statusCode: 404, headers: nil)
        }
        
        let source = DefaultNetworkDataSource()
        let request = TimeRecord(id: UUID(), year: Date.now.year, month: Date.now.month, checkIn: .now, checkOut: .now, breakTimes: [])
        await #expect(throws: DefaultNetworkDataSource.NetworkError.self) {
            try await source.deleteRecord(record: request)
        }
    }
}
