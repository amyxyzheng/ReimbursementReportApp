import SwiftUI
import CoreData

struct IncludedItemsSection: View {
    let report: Report
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        Section(header: Text("Included Items")) {
            if report.type == "meal" {
                let meals = fetchIncludedMeals()
                if meals.isEmpty {
                    Text("No items")
                } else {
                    ForEach(meals, id: \.id) { meal in
                        Text("🍽️ \(meal.occasion ?? "Meal") - \(formattedDate(meal.date))")
                    }
                }
            } else if report.type == "trip" {
                if let trip = fetchIncludedTrip(), let receipts = trip.receipts as? Set<Receipt>, !receipts.isEmpty {
                    ForEach(receipts.sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }, id: \.id) { receipt in
                        HStack {
                            Text(ReceiptCategory(rawValue: receipt.expenseCategory ?? "")?.displayName ?? (receipt.expenseCategory ?? "Receipt"))
                                .font(.subheadline)
                            Spacer()
                            if let date = receipt.date {
                                Text(formattedDate(date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } else if let idStrings = report.includedItemIDs as? [String] {
                    let uuids = idStrings.compactMap { UUID(uuidString: $0) }
                    if uuids.count > 1 {
                        Text("⚠️ Error: Multiple trips found in report data. This indicates a data corruption issue.")
                            .foregroundColor(.red)
                            .font(.caption)
                    } else {
                        Text("No receipts found for this trip.")
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("No items")
            }
        }
    }
    
    private func fetchIncludedMeals() -> [MealItem] {
        guard let idStrings = report.includedItemIDs as? [String] else { return [] }
        let uuids = idStrings.compactMap { UUID(uuidString: $0) }
        let request: NSFetchRequest<MealItem> = MealItem.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", uuids)
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    private func fetchIncludedTrip() -> Trip? {
        guard let idStrings = report.includedItemIDs as? [String],
              let uuid = idStrings.compactMap({ UUID(uuidString: $0) }).first else { return nil }
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        do {
            let trips = try context.fetch(request)
            if trips.count > 1 {
                print("[Error] Multiple trips found for a single-trip report. This indicates a data corruption issue.")
                return nil
            }
            return trips.first
        } catch {
            return nil
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
} 