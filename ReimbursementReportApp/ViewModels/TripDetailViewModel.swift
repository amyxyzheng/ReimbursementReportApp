//
//  TripDetailViewModel.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/13/25.
//

import Foundation
import CoreData
import Combine

class TripDetailViewModel: ObservableObject {
    @Published var receipts: [Receipt] = []
    @Published var transportType: TransportType = .flightTrain
    @Published var originCity: String = ""
    @Published var noTransportReason: NoTransportReason?
    @Published var eventStartDate: Date
    @Published var eventEndDate: Date


    let trip: Trip
    let context: NSManagedObjectContext

    init(trip: Trip,
         context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.trip = trip
        self.context = context
        self.eventStartDate = trip.eventStartDate ?? trip.startDate ?? Date()
        self.eventEndDate   = trip.eventEndDate ?? trip.endDate ?? Date()
        fetchReceipts()
        self.transportType = TransportType(rawValue: trip.transportType ?? "flight_train") ?? .flightTrain
        self.originCity = trip.originCity ?? ""
        self.noTransportReason = NoTransportReason(rawValue: trip.noTransportReason ?? "")

    }

    func fetchReceipts() {
        if let tripReceipts = trip.receipts as? Set<Receipt> {
            receipts = tripReceipts.sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }
        }
    }

    func addReceipt(_ receipt: Receipt) {
        receipt.trip = trip
        saveContext()
        fetchReceipts()
    }

    func deleteReceipt(at offsets: IndexSet) {
        for idx in offsets {
            let receipt = receipts[idx]
            context.delete(receipt)
        }
        saveContext()
        fetchReceipts()
    }
    

    
    func deleteReceipt(_ receipt: Receipt) {
        context.delete(receipt)
        saveContext()
        fetchReceipts()
    }
    
    func toggleReimbursed() {
        trip.reimbursed.toggle()
        saveContext()
    }
    
    func setTransport(_ type: TransportType) {
        transportType = type
        trip.transportType = type.rawValue

        if type == .notApplicable {
            noTransportReason = nil  // Clear prior reason so we can prompt again
        }

        saveContext()
    }

    func setNoTransportReason(_ reason: NoTransportReason) {
        noTransportReason = reason
        trip.noTransportReason = reason.rawValue
        saveContext()
    }
    
    func saveDates() {
        // No need for error handling, picker constrains values
        trip.eventStartDate = eventStartDate
        trip.eventEndDate = eventEndDate
        do { try context.save() }
        catch { print("Failed to save dates:", error) }
    }
    
    private func saveContext() {
        do {
            trip.eventStartDate = eventStartDate
            trip.eventEndDate = eventEndDate
            try context.save()
        } catch { print("Save error: \(error)") }
    }
}

enum TransportType: String, CaseIterable, Identifiable {
    case flightTrain = "flight_train", taxi, drive, notApplicable = "not_applicable"
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .flightTrain: return "Flight/Train"
        case .taxi: return "Taxi"
        case .drive: return "Drive"
        case .notApplicable: return "Not Applicable"
        }
    }
}

// New enum for reasons when transport is not applicable
enum NoTransportReason: String, CaseIterable, Identifiable {
    case localEvent = "local_event"
    case coveredByOtherTrip = "covered_by_other"
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .localEvent: return "Event is Local"
        case .coveredByOtherTrip: return "Covered by Another Trip"
        }
    }
}
