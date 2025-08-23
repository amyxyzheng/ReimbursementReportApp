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
    @State private var pickerSource: PickerSource?
    @State private var isTransportationExpanded = false
    @State private var showingDocumentPicker = false
    @State private var showingCategorySelection = false
    @State private var pendingReceiptData: Data?
    @State private var pendingReceiptType: String?
    @State private var selectedReceiptCategory: ReceiptCategory = .transport

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
            Section(header: ReceiptSourceSelector(
                showingSourceDialog: $showingSourceDialog,
                pickerSource: $pickerSource,
                showingDocumentPicker: $showingDocumentPicker,
                onImageSelected: { data, type in
                    // Show category selection after image is selected
                    showingCategorySelection = true
                    pendingReceiptData = data
                    pendingReceiptType = type
                },
                onDocumentSelected: { data, mimeType in
                    // Show category selection after document is selected
                    showingCategorySelection = true
                    pendingReceiptData = data
                    pendingReceiptType = mimeType
                }
            )) {
                ReceiptListView(
                    receipts: vm.receipts,
                    onDeleteReceipt: { receipt in
                        vm.deleteReceipt(receipt)
                    }
                )
            }
        }
        .listStyle(InsetGroupedListStyle())
        .onAppear {
            editableTripName = vm.trip.name ?? ""
        }
        .alert("Select Receipt Category", isPresented: $showingCategorySelection) {
            ForEach(ReceiptCategory.allCases, id: \.rawValue) { category in
                Button(category.displayName) {
                    createReceipt(with: category)
                }
            }
            Button("Cancel", role: .cancel) {
                // Clear pending data
                pendingReceiptData = nil
                pendingReceiptType = nil
            }
        } message: {
            Text("Choose a category for this receipt")
        }
        // Remove .alert modifiers for help
    }
    
    private func createReceipt(with category: ReceiptCategory) {
        guard let data = pendingReceiptData, let type = pendingReceiptType else { return }
        
        let receipt = Receipt(context: vm.context)
        receipt.id = UUID()
        receipt.date = Date()
        receipt.data = data
        receipt.type = type
        receipt.expenseCategory = category.rawValue
        vm.addReceipt(receipt)
        
        // Clear pending data
        pendingReceiptData = nil
        pendingReceiptType = nil
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
                    HStack {
                        Text(vm.trip.name ?? "Untitled Trip")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                        
                        if vm.trip.reimbursed {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                        }
                    }
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
        .opacity(vm.trip.reimbursed ? 0.6 : 1.0)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                vm.toggleReimbursed()
            } label: {
                Label(vm.trip.reimbursed ? "Mark Unreimbursed" : "Mark Reimbursed", 
                      systemImage: vm.trip.reimbursed ? "xmark.circle" : "checkmark.circle")
            }
            .tint(vm.trip.reimbursed ? .orange : .green)
        }
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
