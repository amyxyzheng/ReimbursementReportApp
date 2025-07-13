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

    init(viewModel: TripListViewModel, editingTrip: Trip? = nil) {
        self.viewModel = viewModel
        self.editingTrip = editingTrip

        _name = State(initialValue: editingTrip?.name ?? "")
        _city = State(initialValue: editingTrip?.destinationCity ?? "")
        _country = State(initialValue: editingTrip?.destinationCountry ?? "")
        _startDate = State(initialValue: editingTrip?.startDate ?? Date())
        _endDate = State(initialValue: editingTrip?.endDate ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Info") {
                    TextField("Name", text: $name)
                    TextField("City", text: $city)
                    TextField("Country", text: $country)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
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
                            viewModel.fetchTrips()
                        } else {
                            // Create new
                            viewModel.addTrip(
                                name: name,
                                city: city,
                                country: country,
                                startDate: startDate,
                                endDate: endDate
                            )
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}
