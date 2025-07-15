//
//  TripListViewModel.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import Foundation
import CoreData
import Combine

class TripListViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        fetchTrips()
    }

    func fetchTrips() {
        let req: NSFetchRequest<Trip> = Trip.fetchRequest()
        req.sortDescriptors = [
            NSSortDescriptor(keyPath: \Trip.startDate, ascending: false)
        ]
        do {
            trips = try context.fetch(req)
        } catch {
            print("Fetch trips error:", error)
        }
    }

    func addTrip(name: String,
                 city: String,
                 country: String,
                 startDate: Date,
                 endDate: Date,
                 transportType: String,
                 originCity: String,
                 noTransportReason: String?) {
        let trip = Trip(context: context)
        trip.id = UUID()
        trip.name = name
        trip.destinationCity = city
        trip.destinationCountry = country
        trip.startDate = startDate
        trip.endDate = endDate
        trip.transportType = transportType
        trip.originCity = originCity
        trip.noTransportReason = noTransportReason
        // no event ranges yet
        saveAndRefresh()
    }

    func deleteTrips(at offsets: IndexSet) {
        for i in offsets {
            context.delete(trips[i])
        }
        saveAndRefresh()
    }

    private func saveAndRefresh() {
        do {
            try context.save()
            fetchTrips()
        } catch {
            print("Save error:", error)
        }
    }
}
