//
//  RecordEditViewModel.swift
//  TimeCard
//
//  Created by uhimania on 2026/03/04.
//

import Foundation

@Observable
class RecordEditViewModel {
    @ObservationIgnored private let repository: CalendarRecordRepository
    
    var timeViewModel: TimeRecordEditViewModel
    var uptimeViewModel: UptimeRecordEditViewModel
    
    init(_ repository: CalendarRecordRepository, _ date: Date) {
        self.repository = repository
        self.timeViewModel = TimeRecordEditViewModel(date: date)
        self.uptimeViewModel = UptimeRecordEditViewModel(date: date)
        
        if let record = try? repository.getRecord(year: date.year, month: date.month, day: date.day) {
            self.timeViewModel.records = record.timeRecords
            self.uptimeViewModel.records = record.uptimeRecords
        }
    }
    
    func update() {
        let record = CalendarRecord(
            date: timeViewModel.date,
            timeRecords: timeViewModel.records,
            uptimeRecords: uptimeViewModel.records
        )
        try? repository.updateRecord(record)
    }
}

@Observable
class TimeRecordEditViewModel {
    var date: Date
    var records: [TimeRecord] = []
    
    init(date: Date, records: [TimeRecord] = []) {
        self.date = date
        self.records = records
    }
}

@Observable
class UptimeRecordEditViewModel {
    var date: Date
    var records: [SystemUptimeRecord] = []
    
    init(date: Date, records: [SystemUptimeRecord] = []) {
        self.date = date
        self.records = records
    }
}
