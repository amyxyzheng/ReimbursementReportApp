import SwiftUI
import CoreData

struct ReportDetailView: View {
    let report: Report
    @Environment(\.managedObjectContext) private var context
    @State private var showMailComposer = false
    @State private var showShareSheet = false
    @State private var showSummaryShareSheet = false
    @State private var editableSummary: String = ""
    @State private var isEditingSummary: Bool = false
    
    private let maxEmailAttachmentSize: Int = 25 * 1024 * 1024 // 25MB
    
    var body: some View {
        Form {
            Section(header: Text("Report Info")) {
                Text("Type: \(report.type ?? "-")")
                Text("Date Range: \(formattedDate(report.dateRangeStart)) - \(formattedDate(report.dateRangeEnd))")
                Text("Created: \(formattedDate(report.createdAt))")
            }
            SummaryEditorSection(
                summary: $editableSummary,
                isEditing: $isEditingSummary,
                onSave: saveSummary,
                placeholder: "No summary"
            )
            IncludedItemsSection(report: report)
            Section {
                if let zipData = report.zipData, zipData.count > maxEmailAttachmentSize {
                    Text("⚠️ The ZIP file is too large to email (over 25MB). Please use 'Download ZIP' to save or share the file.")
                        .foregroundColor(.red)
                        .padding(.vertical, 4)
                } else {
                    Button(action: {
                        if let zipData = report.zipData {
                            print("[DEBUG] zipData size: \(zipData.count) bytes")
                        } else {
                            print("[DEBUG] zipData is nil")
                        }
                        print("[DEBUG] summary preview: \(report.summaryText?.prefix(200) ?? "nil")")
                        showMailComposer = true
                    }) {
                        Label("Send via Email", systemImage: "envelope")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(report.zipData == nil || (report.summaryText ?? "").isEmpty)
                }
                
                if report.zipData != nil {
                    Button(action: { showShareSheet = true }) {
                        Label("Download ZIP", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                }
                if let summary = report.summaryText, !summary.isEmpty {
                    Button(action: { showSummaryShareSheet = true }) {
                        Label("Download Summary", systemImage: "doc.text")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle("Report Detail")
        .sheet(isPresented: $showMailComposer) {
            if let zipData = report.zipData, let summary = report.summaryText {
                ReportMailComposer(
                    subject: reportTitle(),
                    body: summary,
                    zipData: zipData,
                    zipFilename: reportTitle() + ".zip",
                    onDismiss: { showMailComposer = false }
                )
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let zipData = report.zipData {
                ActivityView(activityItems: [TemporaryFileData(data: zipData, fileName: reportTitle() + ".zip")]) {
                    showShareSheet = false
                }
            }
        }
        .sheet(isPresented: $showSummaryShareSheet) {
            if let summary = report.summaryText, !summary.isEmpty, let data = summary.data(using: .utf8) {
                ActivityView(activityItems: [TemporaryFileData(data: data, fileName: "Summary.txt")]) {
                    showSummaryShareSheet = false
                }
            }
        }
        .onAppear {
            editableSummary = report.summaryText ?? ""
        }
    }
    
    private func saveSummary() {
        if editableSummary != (report.summaryText ?? "") {
            report.summaryText = editableSummary
            try? context.save()
        }
    }
    
    private func reportTitle() -> String {
        let type = (report.type ?? "Expense").capitalized
        let start = formattedDate(report.dateRangeStart)
        let end = formattedDate(report.dateRangeEnd)
        return "\(type) Report \(start)-\(end)"
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct ReportDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a mock Report for preview
        let context = PersistenceController.preview.container.viewContext
        let report = Report(context: context)
                    report.type = "expense"
        report.dateRangeStart = Date()
        report.dateRangeEnd = Calendar.current.date(byAdding: .day, value: 2, to: Date())
        report.createdAt = Date()
        report.summaryText = "Sample summary"
        report.includedItemIDs = [UUID().uuidString, UUID().uuidString] as NSArray
        report.zipData = Data() // Placeholder
        return NavigationView { ReportDetailView(report: report).environment(\.managedObjectContext, context) }
    }
} 
