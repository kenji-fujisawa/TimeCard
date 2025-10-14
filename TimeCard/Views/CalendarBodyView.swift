//
//  CalendarBodyView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/03.
//

import SwiftData
import SwiftUI

struct CalendarBodyView: View {
    var year: Int
    var month: Int
    @Query private var recs: [TimeRecord]
    @State private var recordToEdit: CalendarRecord? = nil
    @State private var showFileExport: Bool = false
    
    private var records: [CalendarRecord] {
        let dates = Calendar.current.datesOf(year: self.year, month: self.month)
        
        var grouped: [Int: [TimeRecord]] = [:]
        for rec in recs {
            if let day = rec.checkIn?.day {
                if grouped[day] == nil {
                    grouped[day] = []
                }
                grouped[day]?.append(rec)
            }
        }
        
        var results: [CalendarRecord] = []
        for date in dates {
            results.append(CalendarRecord(date: date, records: grouped[date.day] ?? []))
        }
        
        return results
    }
    
    init(year: Int, month: Int) {
        self.year = year
        self.month = month
        
        _recs = Query(filter: #Predicate<TimeRecord> { $0.year == year && $0.month == month }, sort: \.checkIn)
    }
    
    var body: some View {
        List {
            Grid(alignment: .leading) {
                GridRow {
                    Text("")
                    Text("出勤")
                        .bold()
                    Text("退勤")
                        .bold()
                    Text("休憩開始")
                        .bold()
                    Text("休憩終了")
                        .bold()
                    Text("労働時間")
                        .bold()
                }
                Divider()
                
                ForEach(records) { record in
                    CalendarRecordView(record: record, fixed: isFixed(record: record), recordToEdit: $recordToEdit)
                    Divider()
                }
                
                GridRow {
                    Text("")
                    Text("")
                    Text("")
                    Text("")
                    Text("")
                    Text(records.timeWorkedSum, format: .timeWorked)
                }
            }
        }
        .sheet(item: $recordToEdit) { record in
            RecordEditView(record: record)
        }
        .fileExporter(isPresented: $showFileExport, item: PdfDocument()) { _ in }
        .focusedSceneValue(\.exportPDFAction, ExportPDFAction(records: records, showExporter: { showFileExport = true }))
    }
    
    private func isFixed(record: CalendarRecord) -> Bool {
        guard let latest = recs.last else {
            return record.date < .now
        }
        
        if record.date.day == latest.checkIn?.day {
            return latest.state == .OffWork
        }
        
        return record.date.day < latest.checkIn?.day ?? Date.now.day
    }
}

#Preview {
    CalendarBodyView(year: 2025, month: 10)
}
