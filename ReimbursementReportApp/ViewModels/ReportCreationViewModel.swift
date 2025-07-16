import Foundation
import SwiftUI
import CoreData

class ReportCreationViewModel: ObservableObject {
    enum ReportType: String, CaseIterable, Identifiable {
        case meal = "Meal"
        case trip = "Trip"
        var id: String { rawValue }
    }
    
    struct SelectableItem: Identifiable {
        let id: UUID
        let name: String
        var isSelected: Bool
        var subtitle: String? = nil // For trip dates
    }
    
    @Published var selectedType: ReportType = .meal {
        didSet { fetchItems() }
    }
    @Published var dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
        return start...end
    }() {
        didSet { fetchItems() }
    }
    @Published var items: [SelectableItem] = []
    @Published var errorMessage: String?
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchItems()
    }
    
    func fetchItems() {
        switch selectedType {
        case .meal:
            let request: NSFetchRequest<MealItem> = MealItem.fetchRequest()
            request.predicate = NSPredicate(
                format: "date >= %@ AND date <= %@",
                dateRange.lowerBound as NSDate,
                dateRange.upperBound as NSDate
            )
            request.sortDescriptors = [NSSortDescriptor(keyPath: \MealItem.date, ascending: false)]
            do {
                let meals = try context.fetch(request)
                items = meals.map { meal in
                    SelectableItem(id: meal.id ?? UUID(), name: meal.occasion ?? "Meal", isSelected: true)
                }
            } catch {
                items = []
            }
        case .trip:
            let request: NSFetchRequest<Trip> = Trip.fetchRequest()
            // Show all trips, no date filter
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Trip.endDate, ascending: false)]
            do {
                let trips = try context.fetch(request)
                items = trips.enumerated().map { (idx, trip) in
                    let dateString: String
                    if let start = trip.startDate, let end = trip.endDate {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        dateString = "\(formatter.string(from: start)) – \(formatter.string(from: end))"
                    } else {
                        dateString = "Dates Unknown"
                    }
                    return SelectableItem(
                        id: trip.id ?? UUID(),
                        name: trip.name ?? "Trip",
                        isSelected: idx == 0, // Only first trip selected by default
                        subtitle: dateString
                    )
                }
            } catch {
                items = []
            }
        }
    }
    
    func toggleSelection(for itemID: UUID) {
        switch selectedType {
        case .meal:
            if let idx = items.firstIndex(where: { $0.id == itemID }) {
                items[idx].isSelected.toggle()
            }
        case .trip:
            // Only allow one trip to be selected at a time
            for idx in items.indices {
                items[idx].isSelected = (items[idx].id == itemID) ? !items[idx].isSelected : false
            }
        }
    }
    
    func generateReport(mileage: String? = nil) -> Bool {
        let selectedIDs = items.filter { $0.isSelected }.map { $0.id.uuidString }
        let includedItemIDs = selectedIDs as NSArray
        
        switch selectedType {
        case .meal:
            // Fetch selected meals
            let request: NSFetchRequest<MealItem> = MealItem.fetchRequest()
            let uuids = items.filter { $0.isSelected }.map { $0.id }
            request.predicate = NSPredicate(format: "id IN %@", uuids)
            do {
                let meals = try context.fetch(request)
                let (summary, zipData, errorMsg) = ReportGenerator.generateMealReport(meals: meals)
                if let errorMsg = errorMsg {
                    errorMessage = errorMsg
                    return false
                }
                guard let summary = summary, let zipData = zipData else {
                    errorMessage = "Unknown error generating report."
                    return false
                }
                let report = Report(context: context)
                report.id = UUID()
                report.type = selectedType.rawValue.lowercased()
                report.dateRangeStart = dateRange.lowerBound
                report.dateRangeEnd = dateRange.upperBound
                report.createdAt = Date()
                report.includedItemIDs = includedItemIDs
                report.summaryText = summary
                report.zipData = zipData
                try context.save()
                return true
            } catch {
                errorMessage = "Error generating report."
                return false
            }
        case .trip:
            // Only one trip can be selected
            guard let selectedTripID = items.first(where: { $0.isSelected })?.id else {
                errorMessage = "Please select a trip."
                return false
            }
            let request: NSFetchRequest<Trip> = Trip.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", selectedTripID as CVarArg)
            do {
                guard let trip = try context.fetch(request).first else {
                    errorMessage = "Trip not found."
                    return false
                }
                let (summary, zipData, errorMsg) = ReportGenerator.generateTripReport(trips: [trip], mileage: mileage)
                if let errorMsg = errorMsg {
                    errorMessage = errorMsg
                    return false
                }
                guard let summary = summary, let zipData = zipData else {
                    errorMessage = "Unknown error generating report."
                    return false
                }
                let report = Report(context: context)
                report.id = UUID()
                report.type = selectedType.rawValue.lowercased()
                report.dateRangeStart = trip.startDate ?? Date()
                report.dateRangeEnd = trip.endDate ?? Date()
                report.createdAt = Date()
                report.includedItemIDs = includedItemIDs
                report.summaryText = summary
                report.zipData = zipData
                try context.save()
                return true
            } catch {
                errorMessage = "Error generating trip report."
                return false
            }
        }
    }
} 