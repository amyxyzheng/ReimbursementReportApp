import SwiftUI
import CoreData

struct ReportsListView: View {
    @State private var showReportCreation = false
    @FetchRequest(
        entity: Report.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Report.createdAt, ascending: false)]
    ) var reports: FetchedResults<Report>
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        NavigationView {
            List {
                ForEach(reports) { report in
                    NavigationLink(destination: ReportDetailView(report: report)) {
                        VStack(alignment: .leading, spacing: 4) {
                            if (report.type ?? "") == "trip" {
                                Text(tripName(for: report) ?? "Trip")
                                    .font(.headline)
                            } else {
                                Text((report.type ?? "Report").capitalized)
                                    .font(.headline)
                            }
                            Text("\(formattedDate(report.dateRangeStart)) - \(formattedDate(report.dateRangeEnd))")
                                .font(.subheadline)
                            Text("Created: \(formattedDate(report.createdAt))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteReport(report)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Reports")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showReportCreation = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showReportCreation) {
                ReportCreationView()
            }
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func deleteReport(_ report: Report) {
        context.delete(report)
        do {
            try context.save()
        } catch {
            // Handle error as needed
        }
    }
    
    // Add helper to fetch trip name for trip reports
    private func tripName(for report: Report) -> String? {
        guard let ids = report.includedItemIDs as? [String],
              let tripID = ids.first,
              let uuid = UUID(uuidString: tripID) else { return nil }
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        request.fetchLimit = 1
        if let trip = try? context.fetch(request).first {
            return trip.name
        }
        return nil
    }
}

struct ReportsListView_Previews: PreviewProvider {
    static var previews: some View {
        ReportsListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 