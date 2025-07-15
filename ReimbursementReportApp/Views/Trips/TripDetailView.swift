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
    @State private var showingImagePicker = false
    @State private var selectedReceiptCategory: ReceiptCategory = .transport
    @State private var selectedPhotoItem: PhotosPickerItem?

    @State private var isTransportationExpanded = false
    @State private var pickerSource: PickerSource?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                destinationHeader
                eventDateSection
                transportationSection
                receiptsSection
            }
        }
        .navigationTitle(vm.trip.name ?? "Trip")
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(isPresented: $showingImagePicker,
                      selection: $selectedPhotoItem,
                      matching: .images)
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    let receipt = Receipt(context: vm.context)
                    receipt.id = UUID()
                    receipt.date = Date()
                    receipt.data = data
                    receipt.type = newItem?.supportedContentTypes.first?.preferredMIMEType
                    receipt.expenseCategory = selectedReceiptCategory.rawValue
                    vm.addReceipt(receipt)
                }
            }
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


    }

    private var destinationHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(vm.trip.name ?? "Untitled Trip")
                .font(.title2)
                .fontWeight(.semibold)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            
            Text("Destination: \(vm.trip.destinationCity ?? "") \(vm.trip.destinationCountry ?? "")")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
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
        .padding(.horizontal)
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
                            // Only collapse if not selecting "Not Applicable"
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
                                // Now collapse after reason is selected
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isTransportationExpanded = false
                                }
                            }
                        }
                    ),
                    isEditable: true
                )
            } else {
                // Show selected transport type when collapsed
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
        .padding(.horizontal)
    }

    private var receiptsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Receipts").font(.headline)
                Spacer()
                Menu {
                    ForEach(ReceiptCategory.allCases, id: \.rawValue) { category in
                        Menu(category.displayName) {
                            Button("Camera") {
                                selectedReceiptCategory = category
                                // Handle camera selection
                                handleReceiptSelection(category: category, source: .camera)
                            }
                            Button("Photo Library") {
                                selectedReceiptCategory = category
                                showingImagePicker = true
                            }
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
                Text("Receipt count: \(vm.receipts.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                VStack(spacing: 8) {
                    ForEach(vm.receipts, id: \.id) { receipt in
                        NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                            HStack {
                                Image(systemName: getReceiptIcon(for: receipt))
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text(receipt.expenseCategory?.capitalized ?? "Receipt")
                                        .font(.subheadline)
                                    if let date = receipt.date {
                                        Text(date.formatted(.dateTime.month().day().year()))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.horizontal)
    }


    
    private func getReceiptIcon(for receipt: Receipt) -> String {
        guard let data = receipt.data else { return "doc.text" }
        
        if UIImage(data: data) != nil {
            return "photo"
        } else {
            return "doc.text"
        }
    }
    
    private func handleReceiptSelection(category: ReceiptCategory, source: PickerSource) {
        selectedReceiptCategory = category
        pickerSource = source
    }
}


enum ReceiptCategory: String, CaseIterable, Identifiable {
    case transport, hotel, upgrade, localTravel
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .transport:
            return "Transport"
        case .hotel:
            return "Hotel"
        case .upgrade:
            return "Upgrade"
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
