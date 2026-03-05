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
    
    init(_ repository: CalendarRecordRepository, _ record: CalendarRecord) {
        self.repository = repository
        self.timeViewModel = TimeRecordEditViewModel(date: record.date, records: record.timeRecords)
        self.uptimeViewModel = UptimeRecordEditViewModel(date: record.date, records: record.uptimeRecords)
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
