//
//  CalendarBodyView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/03.
//

import SwiftUI

struct CalendarBodyView: View {
    @Environment(\.calendarRecordRepository) private var repository
    var viewModel: CalendarViewModel
    @State private var recordToEdit: CalendarRecord? = nil
    @State private var showFileExport: Bool = false
    
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
                    Text("システム稼働時間")
                        .bold()
                        .frame(width: 60, height: 35)
                }
                Divider()
                
                ForEach(viewModel.records) { record in
                    CalendarRecordView(record: record, fixed: isFixed(record: record), recordToEdit: $recordToEdit)
                    Divider()
                }
                
                GridRow {
                    Text("")
                    Text("")
                    Text("")
                    Text("")
                    Text("")
                    Text(viewModel.records.timeWorkedSum, format: .timeWorked)
                    Text(viewModel.records.systemUptimeSum, format: .timeWorked)
                }
                .font(.system(.headline, design: .monospaced))
                .fontWeight(.regular)
            }
        }
        .sheet(item: $recordToEdit) { record in
            RecordEditView(viewModel: RecordEditViewModel(repository, record))
        }
        .fileExporter(isPresented: $showFileExport, document: PdfDocument(), contentType: .pdf, onCompletion: { _ in })
        .focusedSceneValue(\.exportPDFAction, ExportPDFAction(records: viewModel.records, showExporter: { showFileExport = true }))
    }
    
    private func isFixed(record: CalendarRecord) -> Bool {
        let now = Date.now
        if record.date.year == now.year && record.date.month == now.month && record.date.day == now.day {
            let latest = record.timeRecords.last
            return latest != nil && latest?.checkIn != nil && latest?.checkOut != nil
        }
        
        return record.date < now
    }
}

#Preview {
    let repository = FakeCalendarRecordRepository()
    let viewModel = CalendarViewModel(repository)
    CalendarBodyView(viewModel: viewModel)
}

private class FakeCalendarRecordRepository: CalendarRecordRepository {
    func getRecordsStream(year: Int, month: Int) -> AsyncStream<[CalendarRecord]> {
        AsyncStream { continuation in
            let records = Calendar.current.datesOf(year: year, month: month).map { date in
                CalendarRecord(date: date, timeRecords: [], uptimeRecords: [])
            }
            continuation.yield(records)
        }
    }
    
    func updateRecord(_ record: CalendarRecord) throws {}
}
