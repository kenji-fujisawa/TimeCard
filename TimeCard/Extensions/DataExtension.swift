//
//  DataExtension.swift
//  TimeCard
//
//  Created by uhimania on 2026/05/07.
//

import Foundation

extension Data {
    func base64URLEncodedString() -> String {
        self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    init?(base64URLEncoded: String) {
        var base64Encoded = base64URLEncoded
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64Encoded.count % 4 != 0 {
            base64Encoded.append("=")
        }
        self.init(base64Encoded: base64Encoded)
    }
}
