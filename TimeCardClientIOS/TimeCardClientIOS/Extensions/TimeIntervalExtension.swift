//
//  TimeIntervalExtension.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/07.
//

import Foundation

extension TimeInterval {
    func formatted() -> TimeWorkedFormatStyle.FormatOutput {
        TimeWorkedFormatStyle.timeWorked.format(self)
    }
    
    struct TimeWorkedFormatStyle: Foundation.FormatStyle {
        func format(_ value: TimeInterval) -> String {
            let hours = floor(value / 60 / 60)
            let minutes = floor((value - hours * 60 * 60) / 60)
            return String(format: "%02d", Int(hours)) + ":" + String(format: "%02d", Int(minutes))
        }
    }
}

extension FormatStyle where Self == TimeInterval.TimeWorkedFormatStyle {
    static var timeWorked: Self { .init() }
}
