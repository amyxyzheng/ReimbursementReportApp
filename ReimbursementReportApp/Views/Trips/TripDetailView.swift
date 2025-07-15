//
//  TripDetailView.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import SwiftUI
import PhotosUI

struct TripDetailView: View {
    @StateObject var vm: TripDetailViewModel
    @State private var showingSourceDialog = false
    @State private var selectedReceiptCategory: ReceiptCategory = .transport
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pickerSource: PickerSource?
    @State private var isTransportationExpanded = false

    @State private var editableTripName: String = ""
    @FocusState private var isEditingTripName: Bool
    @State private var isEditingName: Bool = false

    // Add state for help popups
    // @State private var showTransportHelp = false
    // @State private var showLocalTravelHelp = false

    var body: some View {
        List {
            Section {
                destinationHeader
                eventDateSection
                transportationSection
            }
            Section(header: receiptsSectionHeader) {
                if vm.receipts.isEmpty {
                    VStack {
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No receipts yet")
                            .foregroundColor(.secondary)
                        Text("Receipt count: \(vm.receipts.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(vm.receipts, id: \.id) { receipt in
                        NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                            HStack {
                                Image(systemName: getReceiptIcon(for: receipt))
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text(ReceiptCategory(rawValue: receipt.expenseCategory ?? "")?.displayName ?? "Receipt")
                                        .font(.subheadline)
                                    if let date = receipt.date {
                                        Text(date.formatted(.dateTime.month().day().year()))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .onDelete(perform: vm.deleteReceipt)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .confirmationDialog("Select Source", isPresented: $showingSourceDialog, titleVisibility: .visible) {
            Button("Camera") {
                selectedPhotoItem = nil // Clear previous selection
                pickerSource = .camera
            }
            Button("Photo Library") {
                selectedPhotoItem = nil // Clear previous selection
                pickerSource = .photoLibrary
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(item: $pickerSource) { source in
            ImagePicker(
                sourceType: source.sourceType,
                onImageSelected: { data, type in
                    let receipt = Receipt(context: vm.context)
                    receipt.id = UUID()
                    receipt.date = Date()
                    receipt.data = data
                    receipt.type = type
                    receipt.expenseCategory = selectedReceiptCategory.rawValue
                    vm.addReceipt(receipt)
                },
                pickerSource: $pickerSource
            )
        }
        .onAppear {
            editableTripName = vm.trip.name ?? ""
        }
        // Remove .alert modifiers for help
    }

    private var destinationHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                if isEditingName {
                    TextEditor(text: $editableTripName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .focused($isEditingTripName)
                        .frame(minHeight: 44, maxHeight: 120)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .scrollContentBackground(.hidden)
                    Button("Save") {
                        vm.trip.name = editableTripName
                        try? vm.context.save()
                        vm.objectWillChange.send()
                        isEditingName = false
                        isEditingTripName = false
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
                } else {
                    Text(vm.trip.name ?? "Untitled Trip")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                    Button("Edit") {
                        editableTripName = vm.trip.name ?? ""
                        isEditingName = true
                        isEditingTripName = true
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
                }
            }
            Text("Destination: \(vm.trip.destinationCity ?? "") \(vm.trip.destinationCountry ?? "")")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var eventDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Event Dates").font(.headline)
            HStack {
                VStack(alignment: .leading) {
                    Text("Start Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $vm.eventStartDate, displayedComponents: .date)
                        .labelsHidden()
                        .onChange(of: vm.eventStartDate) { _ in vm.saveDates() }
                }
                VStack(alignment: .leading) {
                    Text("End Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $vm.eventEndDate, displayedComponents: .date)
                        .labelsHidden()
                        .onChange(of: vm.eventEndDate) { _ in vm.saveDates() }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var transportationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Transportation").font(.headline)
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isTransportationExpanded.toggle()
                    }
                }) {
                    Image(systemName: isTransportationExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
            }
            if isTransportationExpanded {
                TransportationSelector(
                    transportType: Binding(
                        get: { vm.transportType },
                        set: { newType in
                            vm.setTransport(newType)
                            if newType != .notApplicable {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isTransportationExpanded = false
                                }
                            }
                        }
                    ),
                    originCity: $vm.originCity,
                    noTransportReason: Binding(
                        get: { vm.noTransportReason },
                        set: { reason in
                            if let reason = reason {
                                vm.setNoTransportReason(reason)
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isTransportationExpanded = false
                                }
                            }
                        }
                    ),
                    isEditable: true
                )
            } else {
                HStack {
                    Text(vm.transportType.displayName)
                        .foregroundColor(.secondary)
                    Spacer()
                    if vm.transportType == .drive && !vm.originCity.isEmpty {
                        Text("from \(vm.originCity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 4)
    }

    private var receiptsSectionHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Receipts").font(.headline)
                Spacer()
                Menu {
                    ForEach(ReceiptCategory.allCases, id: \.rawValue) { category in
                        Button(action: {
                            selectedReceiptCategory = category
                            selectedPhotoItem = nil // Clear previous selection
                            showingSourceDialog = true
                        }) {
                            Text(category.displayName)
                        }
                    }
                } label: {
                    Text("Add")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
            }
            Text("Receipt count: \(vm.receipts.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func getReceiptIcon(for receipt: Receipt) -> String {
        guard let data = receipt.data else { return "doc.text" }
        if UIImage(data: data) != nil {
            return "photo"
        } else {
            return "doc.text"
        }
    }
}


enum ReceiptCategory: String, CaseIterable, Identifiable {
    case transport, hotel, upgrade, localTravel
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .transport:
            return "Transportation"
        case .hotel:
            return "Hotel"
        case .upgrade:
            return "Flight Upgrade"
        case .localTravel:
            return "Local Travel"
        }
    }
}

#if DEBUG
import SwiftUI
import CoreData

struct TripDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Get the preview context
        let context = PersistenceController.preview.container.viewContext
        
        // Create a sample Trip object
        let sampleTrip = Trip(context: context)
        sampleTrip.id = UUID()
        sampleTrip.name = "Sample Conference"
        sampleTrip.destinationCity = "San Francisco"
        sampleTrip.destinationCountry = "USA"
        sampleTrip.startDate = Date()
        sampleTrip.endDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())
        sampleTrip.transportType = "flight"
        sampleTrip.originCity = "Home City"
        
        // Create sample receipts if needed
        // (Optional: add receipts to sampleTrip.receipts if your UI shows them)
        
        // Initialize your ViewModel with the sample trip
        let vm = TripDetailViewModel(trip: sampleTrip, context: context)
        
        return NavigationView {
            TripDetailView(vm: vm)
                .environment(\.managedObjectContext, context)
        }
    }
}
#endif
