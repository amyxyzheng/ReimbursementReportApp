//
//  AddTripView.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import SwiftUI

struct AddTripView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TripListViewModel
    var editingTrip: Trip?

    @State private var name: String
    @State private var city: String
    @State private var country: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var transportType: TransportType
    @State private var originCity: String
    @State private var noTransportReason: NoTransportReason?


    init(viewModel: TripListViewModel, editingTrip: Trip? = nil) {
        self.viewModel = viewModel
        self.editingTrip = editingTrip

        _name = State(initialValue: editingTrip?.name ?? "")
        _city = State(initialValue: editingTrip?.destinationCity ?? "")
        _country = State(initialValue: editingTrip?.destinationCountry ?? "")
        _startDate = State(initialValue: editingTrip?.startDate ?? Date())
        _endDate = State(initialValue: editingTrip?.endDate ?? Date())
        _transportType = State(initialValue: TransportType(rawValue: editingTrip?.transportType ?? "flight_train") ?? .flightTrain)
        _originCity = State(initialValue: editingTrip?.originCity ?? "")
        _noTransportReason = State(initialValue: NoTransportReason(rawValue: editingTrip?.noTransportReason ?? ""))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Info") {
                    TextField("Name", text: $name)
                        .onChange(of: name) { newValue in
                            if newValue.count > 50 {
                                name = String(newValue.prefix(50))
                            }
                        }
                    TextField("City", text: $city)
                    TextField("Country", text: $country)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section("Transportation") {
                    TransportationSelector(
                        transportType: $transportType,
                        originCity: $originCity,
                        noTransportReason: $noTransportReason,
                        isEditable: true
                    )
                }
                // Future: EventDateRanges list & add
            }
            .navigationTitle(editingTrip == nil ? "Add Trip" : "Edit Trip")

            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingTrip == nil ? "Save" : "Update") {
                        guard !name.isEmpty, !city.isEmpty, !country.isEmpty else { return }
                        if let trip = editingTrip {
                            // Update existing
                            trip.name = name
                            trip.destinationCity = city
                            trip.destinationCountry = country
                            trip.startDate = startDate
                            trip.endDate = endDate
                            trip.transportType = transportType.rawValue
                            trip.originCity = originCity
                            trip.noTransportReason = noTransportReason?.rawValue
                            viewModel.fetchTrips()
                        } else {
                            // Create new
                            viewModel.addTrip(
                                name: name,
                                city: city,
                                country: country,
                                startDate: startDate,
                                endDate: endDate,
                                transportType: transportType.rawValue,
                                originCity: originCity,
                                noTransportReason: noTransportReason?.rawValue
                            )
                        }
                        dismiss()
                    }
                }
            }
        }
    }
    

}

#if DEBUG
import SwiftUI
import CoreData

struct AddTripView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext

        let sampleTrip = Trip(context: context)
        sampleTrip.setValue(UUID(), forKey: "id") // use KVC if direct assignment errors
        sampleTrip.name = "Sample Conference"
        sampleTrip.destinationCity = "New York"
        sampleTrip.destinationCountry = "USA"
        sampleTrip.startDate = Date()
        sampleTrip.endDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())

        return Group {
            AddTripView(viewModel: TripListViewModel())
                .environment(\.managedObjectContext, context)
                .previewDisplayName("Add Trip")

            AddTripView(viewModel: TripListViewModel(), editingTrip: sampleTrip)
                .environment(\.managedObjectContext, context)
                .previewDisplayName("Edit Trip")
        }
    }
}
#endif
