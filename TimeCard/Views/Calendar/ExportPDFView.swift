//
//  ExportPDFView.swift
//  TimeCard
//
//  Created by uhimania on 2025/10/14.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct PdfDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.pdf]
    static let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent("tmp.pdf")
    
    init() {
    }
    
    init(configuration: ReadConfiguration) throws {
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: PdfDocument.tmpPath)
    }
}

struct ExportPDFAction {
    var records: [CalendarRecord]
    var showExporter: () -> Void
}

struct ExportPDFKey: FocusedValueKey {
    typealias Value = ExportPDFAction
}

extension FocusedValues {
    var exportPDFAction: ExportPDFAction? {
        get { self[ExportPDFKey.self] }
        set { self[ExportPDFKey.self] = newValue }
    }
}

struct ExportPDFView: View {
    @FocusedValue(\.exportPDFAction) private var action
    
    var body: some View {
        Button {
            exportPdf()
            action?.showExporter()
        } label: {
            Image(systemName: "printer")
        }
        .help("Export PDF")
    }
    
    private func exportPdf() {
        guard let action = action else { return }
        let view = PDFView(records: action.records)
        let renderer = ImageRenderer(content: view)
        renderer.render { size, renderer in
            var mediaBox = CGRect(origin: .zero, size: CGSize(width: 400, height: computeHeight()))
            guard let consumer = CGDataConsumer(url: PdfDocument.tmpPath as CFURL),
                  let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return }
            pdfContext.beginPDFPage(nil)
            pdfContext.translateBy(x: mediaBox.size.width / 2 - size.width / 2, y: mediaBox.size.height / 2 - size.height / 2)
            renderer(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
        }
    }
    
    private func computeHeight() -> CGFloat {
        guard let action = action else { return 0 }
        
        var height: CGFloat = 0
        let lineHeight: CGFloat = 15
        let dividerHeight: CGFloat = 15
        let headerHeight: CGFloat = 100
        let footerHeight: CGFloat = 15
        
        for record in action.records {
            var lines = 0
            if record.records.isEmpty {
                lines += 1
            } else {
                for rec in record.records {
                    lines += max(rec.breakTimes.count, 1)
                }
            }
            
            height += CGFloat(lines) * lineHeight + dividerHeight
        }
        
        return height + headerHeight + footerHeight
    }
}

private struct PDFView: View {
    var records: [CalendarRecord]
    @State private var recordToEdit: CalendarRecord?
    
    var body: some View {
        VStack(alignment: .leading) {
            if let date = records.first?.date {
                Text(date, format: .dateTime.year().month())
                    .font(.title)
                    .padding(.bottom)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            
            HStack {
                Text("00(月)")
                    .opacity(0)
                    .font(.system(.headline, design: .monospaced))
                ZStack {
                    Text("出勤")
                    Text("00:00")
                        .opacity(0)
                        .font(.system(.headline, design: .monospaced))
                }
                ZStack {
                    Text("退勤")
                    Text("00:00")
                        .opacity(0)
                        .font(.system(.headline, design: .monospaced))
                }
                Text("休憩開始")
                    .font(.system(.subheadline, design: .monospaced))
                Text("休憩終了")
                    .font(.system(.subheadline, design: .monospaced))
                Text("勤務時間")
                    .font(.system(.subheadline, design: .monospaced))
                Text("システム稼働時間")
                    .font(.system(.subheadline, design: .monospaced))
                    .frame(width: 50)
            }
            Divider()
            
            ForEach(records) { record in
                HStack(alignment: .top) {
                    CalendarRecordView(record: record, fixed: false, recordToEdit: $recordToEdit)
                }
                Divider()
            }
            
            HStack {
                Text("00(月)")
                    .opacity(0)
                Text("00:00")
                    .opacity(0)
                Text("00:00")
                    .opacity(0)
                Text("00:00")
                    .opacity(0)
                Text("00:00")
                    .opacity(0)
                Text(records.timeWorkedSum, format: .timeWorked)
                Text(records.systemUptimeSum, format: .timeWorked)
            }
            .font(.system(.headline, design: .monospaced))
            .fontWeight(.regular)
        }
    }
}

#Preview {
    ExportPDFView()
}

#Preview {
    let record = CalendarRecord(
        date: .now,
        records: [
            TimeRecord(
                year: Date.now.year,
                month: Date.now.month,
                checkIn: .now,
                checkOut: Date(timeInterval: 26 * 60 * 60, since: .now),
                breakTimes: [
                    TimeRecord.BreakTime(
                        start: .now,
                        end: Date(timeInterval: 25 * 60 * 60, since: .now)
                    ),
                    TimeRecord.BreakTime(
                        start: .now
                    )
                ]
            ),
            TimeRecord(
                year: Date.now.year,
                month: Date.now.month,
                checkIn: .now,
                breakTimes: [
                    TimeRecord.BreakTime(
                        start: .now,
                        end: Date(timeInterval: 25 * 60 * 60, since: .now)
                    )
                ]
            )
        ],
        systemUptimeRecords: [
            SystemUptimeRecord(
                year: Date.now.year,
                month: Date.now.month,
                day: Date.now.day,
                launch: .now,
                shutdown: .now
            )
        ]
    )
    PDFView(records: [record, record])
}
