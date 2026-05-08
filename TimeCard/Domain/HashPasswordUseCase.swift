//
//  HashPasswordUseCase.swift
//  TimeCard
//
//  Created by uhimania on 2026/05/01.
//

import Foundation

class HashPasswordUseCase {
    func execute(_ password: String) throws -> String {
        try HMACSHA256.computeHash(password).base64EncodedString()
    }
}
