//
//  SecureDataSource.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2026/08/14.
//

import Foundation

protocol SecureDataSource {
    func save(_ value: String, forKey key: String) throws
    func load(forKey key: String) throws -> String
    func remove(forKey key: String) throws
}

class KeyChainDataSource: SecureDataSource {
    struct KeyChainAccessError: Error {
        let code: Int
    }
    
    private let secClass: CFString
    
    init(_ secClass: CFString = kSecClassGenericPassword) {
        self.secClass = secClass
    }
    
    func save(_ value: String, forKey key: String) throws {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: secClass,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let query: [String: Any] = [
                kSecClass as String: secClass,
                kSecAttrAccount as String: key
            ]
            let attrs: [String: Any] = [
                kSecValueData as String: data
            ]
            let status = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
            if status != errSecSuccess {
                throw KeyChainAccessError(code: Int(status))
            }
        } else if status != errSecSuccess {
            throw KeyChainAccessError(code: Int(status))
        }
    }
    
    func load(forKey key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: secClass,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeyChainAccessError(code: Int(status))
        }
        
        return value
    }
    
    func remove(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: secClass,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            throw KeyChainAccessError(code: Int(status))
        }
    }
}
