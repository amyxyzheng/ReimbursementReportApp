//
//  TripListView.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import SwiftUI
import CoreData

struct TripListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Trip.startDate, ascending: false)],
        animation: .default)
    private var trips: FetchedResults<Trip>
    @State private var showingAdd = false

    var body: some View {
        NavigationView {
            List {
                ForEach(trips, id: \.id) { trip in
                    NavigationLink(destination: TripDetailView(vm: TripDetailViewModel(trip: trip))) {
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
                .onDelete(perform: deleteTrips)
            }
            .navigationTitle("Trips")
            .toolbar {
                Button(action: { showingAdd = true }) {
                    Label("Add Trip", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddTripView(viewModel: TripListViewModel(context: viewContext))
            }
        }
    }

    private func deleteTrips(at offsets: IndexSet) {
        for index in offsets {
            let trip = trips[index]
            viewContext.delete(trip)
        }
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete trip: \(error)")
        }
    }
}
