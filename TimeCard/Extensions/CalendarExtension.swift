//
//  CalendarExtension.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/02.
//

import Foundation

extension Calendar {
    func datesOf(year: Int, month: Int) -> [Date] {
        var dates: [Date] = []
        
        var date = Calendar.current.date(from: DateComponents(year: year, month: month))
        while date?.month == month {
            guard let d = date else { break }
            dates.append(d)
            date = Calendar.current.date(byAdding: DateComponents(day: 1), to: d)
        }
        
        return dates
    }
}
