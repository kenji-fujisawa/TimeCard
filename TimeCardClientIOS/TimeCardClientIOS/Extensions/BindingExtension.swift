//
//  BindingExtension.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/09.
//

import Foundation
import SwiftUI

extension Binding {
    func bindUnwrap<T>(defaultValue: T) -> Binding<T> where Value == T? {
        Binding<T>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 }
        )
    }
}
