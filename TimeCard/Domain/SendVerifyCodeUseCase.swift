//
//  SendVerifyCodeUseCase.swift
//  TimeCard
//
//  Created by uhimania on 2026/04/28.
//

import Foundation

protocol SendVerifyCodeUseCase {
    func execute(mail: String, verifyCode: String) async throws
}
