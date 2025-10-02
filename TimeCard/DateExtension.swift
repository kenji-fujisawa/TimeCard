//
//  DateExtension.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/02.
//

import Foundation
import JapaneseNationalHolidays

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
    
    var weekDay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }
    
    func isHoliday() -> Bool {
        let weekday = Calendar.current.component(.weekday, from: self)
        return weekday == 1 || weekday == 7 || self.japaneseNationalHolidayName != nil
    }
}
