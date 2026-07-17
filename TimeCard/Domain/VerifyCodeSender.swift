//
//  VerifyCodeSender.swift
//  TimeCard
//
//  Created by uhimania on 2026/04/28.
//

import Foundation
import SwiftSMTP

protocol VerifyCodeSender {
    func send(to recipient: String, verifyCode: String, expire: Date) async throws
}

class MailVerifyCodeSender: VerifyCodeSender {
    private let host: String
    private let port: Int
    private let username: String
    private let password: String
    private let senderName: String
    private let senderAddress: String
    private let allowSelfCertificate: Bool
    
    init(host: String, port: Int, username: String, password: String, senderName: String, senderAddress: String, allowSelfCertificate: Bool) {
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.senderName = senderName
        self.senderAddress = senderAddress
        self.allowSelfCertificate = allowSelfCertificate
    }
    
    func send(to recipient: String, verifyCode: String, expire: Date) async throws {
        let config = TLSConfiguration(clientAllowsSelfSignedCertificates: allowSelfCertificate)
        let smtp = SMTP(hostname: host, email: username, password: password, port: Int32(port), tlsConfiguration: config)
        let from = Mail.User(name: senderName, email: senderAddress)
        let to = Mail.User(email: recipient)
        let mail = Mail(
            from: from,
            to: [to],
            subject: "[TimeCard] 確認コードのおしらせ",
            text: """
                確認コード : \(verifyCode)
                有効期限 : \(expire.formatted())
                """
        )
        
        var result: Error? = nil
        smtp.send(mail) { error in
            result = error
        }
        
        if let error = result {
            throw error
        }
    }
}
