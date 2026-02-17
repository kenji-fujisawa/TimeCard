//
//  DateExtension.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/02.
//

import Foundation
import JapanHolidays

extension Date {
    var year: Int {
        Calendar.current.component(.year, from: self)
    }
    
    var month: Int {
        Calendar.current.component(.month, from: self)
    }
    
    var day: Int {
        Calendar.current.component(.day, from: self)
    }
    
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }
    
    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }
    
    var second: Int {
        Calendar.current.component(.second, from: self)
    }
    
    var weekDay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }
    
    func isHoliday() -> Bool {
        let weekday = Calendar.current.component(.weekday, from: self)
        return weekday == 1 || weekday == 7 || Holidays.isHoliday(self)
    }
    
    struct DayWithWeekdayFormatStyle: Foundation.FormatStyle {
        func format(_ value: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd(E)"
            formatter.locale = Locale(identifier: "ja_JP")
            return formatter.string(from: value)
        }
    }
}

extension FormatStyle where Self == Date.DayWithWeekdayFormatStyle {
    static var dayWithWeekday: Self { .init() }
}
