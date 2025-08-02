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
    @State private var showingDocumentPicker = false
    @State private var customCategoryName = ""
    @State private var showingCustomCategoryAlert = false

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
                perDiemSection
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
                                    Text(getReceiptDisplayName(for: receipt))
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
            Button("PDF File") {
                selectedPhotoItem = nil // Clear previous selection
                showingDocumentPicker = true
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
                    let categoryName = selectedReceiptCategory == .other ? customCategoryName : selectedReceiptCategory.rawValue
                    receipt.expenseCategory = categoryName
                    vm.addReceipt(receipt)
                    customCategoryName = "" // Reset for next use
                },
                pickerSource: $pickerSource
            )
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { data, mimeType in
                let receipt = Receipt(context: vm.context)
                receipt.id = UUID()
                receipt.date = Date()
                receipt.data = data
                receipt.type = mimeType
                let categoryName = selectedReceiptCategory == .other ? customCategoryName : selectedReceiptCategory.rawValue
                receipt.expenseCategory = categoryName
                vm.addReceipt(receipt)
                customCategoryName = "" // Reset for next use
            }
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                                .opacity(0.3)
                        )
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
            if let start = vm.trip.startDate, let end = vm.trip.endDate {
                Text("Trip Dates: \(start.formatted(date: .numeric, time: .omitted)) to \(end.formatted(date: .numeric, time: .omitted))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var eventDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Event Dates").font(.headline)
            
            if let tripStartDate = vm.trip.startDate,
               let tripEndDate = vm.trip.endDate {
                HStack {
                    VStack(alignment: .leading) {
                        CustomDatePicker(
                            title: "Start Date",
                            date: Binding(
                                get: { vm.eventStartDate },
                                set: { 
                                    vm.eventStartDate = $0
                                    vm.saveDates()
                                }
                            ),
                            displayedComponents: .date,
                            minDate: tripStartDate,
                            maxDate: vm.eventEndDate
                        )
                    }
                    VStack(alignment: .leading) {
                        CustomDatePicker(
                            title: "End Date",
                            date: Binding(
                                get: { vm.eventEndDate },
                                set: { 
                                    vm.eventEndDate = $0
                                    vm.saveDates()
                                }
                            ),
                            displayedComponents: .date,
                            minDate: vm.eventStartDate,
                            maxDate: tripEndDate
                        )
                    }
                }
            } else {
                Text("Trip dates not available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var perDiemSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Per Diem Summary").font(.headline)
            if let perDiemInfo = PerDiemCalculator.calculatePerDiem(for: vm.trip) {
                VStack(alignment: .leading, spacing: 4) {
                    if perDiemInfo.travelDays > 0 {
                        let travelDates = perDiemInfo.travelDayDates.map { $0.formatted(date: .numeric, time: .omitted) }.joined(separator: ", ")
                        (
                            Text("Travel Days: ") +
                            Text("\(perDiemInfo.travelDays)").foregroundColor(.orange) +
                            Text(" (\(travelDates))")
                        )
                        .font(.subheadline)
                    }
                    if let eventStart = perDiemInfo.eventDayDates.first, let eventEnd = perDiemInfo.eventDayDates.last {
                        (
                            Text("Event Days: ") +
                            Text("\(perDiemInfo.eventDays)").foregroundColor(.green) +
                            Text(" (\(eventStart.formatted(date: .numeric, time: .omitted)) to \(eventEnd.formatted(date: .numeric, time: .omitted)))")
                        )
                        .font(.subheadline)
                    }
                }
            } else {
                Text("Unable to calculate per diem information")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
                            if category == .other {
                                showingCustomCategoryAlert = true
                            } else {
                                selectedPhotoItem = nil // Clear previous selection
                                showingSourceDialog = true
                            }
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
        .alert("Custom Category", isPresented: $showingCustomCategoryAlert) {
            TextField("Category name", text: $customCategoryName)
            Button("Cancel", role: .cancel) {
                customCategoryName = ""
            }
            Button("Add Receipt") {
                selectedPhotoItem = nil // Clear previous selection
                showingSourceDialog = true
            }
        } message: {
            Text("Enter a name for this receipt category:")
        }
    }

    private func getReceiptIcon(for receipt: Receipt) -> String {
        if receipt.type == "application/pdf" {
            return "doc.text"
        } else if let data = receipt.data, UIImage(data: data) != nil {
            return "photo"
        } else {
            return "doc.text"
        }
    }
    
    private func getReceiptDisplayName(for receipt: Receipt) -> String {
        guard let category = receipt.expenseCategory else { return "Receipt" }
        
        // First try to match with predefined categories
        if let predefinedCategory = ReceiptCategory(rawValue: category) {
            return predefinedCategory.displayName
        }
        
        // If not a predefined category, it's a custom category name
        return category
    }
}


enum ReceiptCategory: String, CaseIterable, Identifiable {
    case transport, hotel, upgrade, localTravel, other
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .transport:
            return "Major Transport"
        case .hotel:
            return "Hotel"
        case .upgrade:
            return "Flight Upgrade"
        case .localTravel:
            return "Local Transit"
        case .other:
            return "Other"
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
