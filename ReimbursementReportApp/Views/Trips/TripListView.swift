//
//  TripListView.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import SwiftUI

struct TripListView: View {
    @StateObject var vm = TripListViewModel()
    @State private var showingAdd = false
    @State private var editingTrip: Trip? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(vm.trips, id: \.id) { trip in
                    Button {
                        editingTrip = trip
                    } label: {
                        VStack(alignment: .leading) {
                            Text(trip.name ?? "(No Name)")
                                .font(.headline)
                            Text("\(trip.destinationCity ?? ""), \(trip.destinationCountry ?? "")")
                                .font(.subheadline)
                            HStack {
                                Text(trip.startDate?.formatted(date: .numeric, time: .omitted) ?? "")
                                Text("–")
                                Text(trip.endDate?.formatted(date: .numeric, time: .omitted) ?? "")
                            }
                            .font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: vm.deleteTrips)
            }
            .navigationTitle("Trips")
            .toolbar {
                Button(action: { showingAdd = true }) {
                    Label("Add Trip", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddTripView(viewModel: vm)
            }
            .sheet(item: $editingTrip) { trip in
                AddTripView(viewModel: vm, editingTrip: trip)
            }
        }
    }
}
