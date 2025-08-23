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
                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(trip.name ?? "(No Name)")
                                        .font(.headline)
                                    
                                    if trip.reimbursed {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    }
                                }
                                Text("\(trip.destinationCity ?? ""), \(trip.destinationCountry ?? "")")
                                    .font(.subheadline)
                                HStack {
                                    Text(trip.startDate?.formatted(date: .numeric, time: .omitted) ?? "")
                                    Text("–")
                                    Text(trip.endDate?.formatted(date: .numeric, time: .omitted) ?? "")
                                }
                                .font(.caption)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .opacity(trip.reimbursed ? 0.6 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            toggleTripReimbursed(trip)
                        } label: {
                            Label(trip.reimbursed ? "Mark Unreimbursed" : "Mark Reimbursed", 
                                  systemImage: trip.reimbursed ? "xmark.circle" : "checkmark.circle")
                        }
                        .tint(trip.reimbursed ? .orange : .green)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteTrip(trip)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
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

    private func deleteTrip(_ trip: Trip) {
        // Delete all receipts associated with this trip
        if let tripReceipts = trip.receipts as? Set<Receipt> {
            for receipt in tripReceipts {
                viewContext.delete(receipt)
            }
        }
        
        // Delete the trip itself
        viewContext.delete(trip)
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete trip: \(error)")
        }
    }
    
    private func toggleTripReimbursed(_ trip: Trip) {
        trip.reimbursed.toggle()
        do {
            try viewContext.save()
        } catch {
            print("Failed to update trip reimbursement status: \(error)")
        }
    }
}
