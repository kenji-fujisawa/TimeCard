//
//  JsonWebToken.swift
//  TimeCard
//
//  Created by uhimania on 2026/05/07.
//

import Foundation

enum JWT {
    enum JWTError: Error {
        case invalidFormat
        case invalidSignature
        case invalidHeader
        case invalidAlgorithm
        case invalidType
        case invalidPayload
        case invalidIssuer
        case invalidAudience
        case expired
    }
    
    private static let algorithm = "HS256"
    private static let type = "JWT"
    private static let issuer = "TimeCard"
    private static let audience = "TimeCardClient"
    
    struct Header: Codable {
        var alg: String = algorithm
        var typ: String = type
    }
    
    struct Payload: Codable {
        var sub: String
        var exp: Date
        var iss: String = issuer
        var aud: String = audience
    }
    
    static func encode(sub: String, exp: Date) throws -> String {
        let encoder = JSONEncoder()
        let header = try encoder.encode(Header()).base64URLEncodedString()
        let payload = try encoder.encode(Payload(sub: sub, exp: exp)).base64URLEncodedString()
        let signature = try HMACSHA256.computeHash("\(header).\(payload)").base64URLEncodedString()
        return "\(header).\(payload).\(signature)"
    }
    
    static func decode(_ token: String) throws -> String {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { throw JWTError.invalidFormat }
        
        let signature = try? HMACSHA256.computeHash("\(parts[0]).\(parts[1])").base64URLEncodedString()
        guard parts[2] == signature ?? "" else { throw JWTError.invalidSignature }
        
        let decoder = JSONDecoder()
        guard let header = try? decoder.decode(Header.self, from: Data(base64URLEncoded: String(parts[0])) ?? Data()) else { throw JWTError.invalidHeader }
        guard header.alg == algorithm else { throw JWTError.invalidAlgorithm }
        guard header.typ == type else { throw JWTError.invalidType }
        
        guard let payload = try? decoder.decode(Payload.self, from: Data(base64URLEncoded: String(parts[1])) ?? Data()) else { throw JWTError.invalidPayload }
        guard payload.iss == issuer else { throw JWTError.invalidIssuer }
        guard payload.aud == audience else { throw JWTError.invalidAudience }
        guard payload.exp > .now else { throw JWTError.expired }
        
        return payload.sub
    }
}
