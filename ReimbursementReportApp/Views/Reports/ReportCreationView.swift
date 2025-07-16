import SwiftUI
import CoreData

struct ReportCreationView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: ReportCreationViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Mileage prompt state
    @State private var showMileagePrompt = false
    @State private var mileageInput: String = ""
    @State private var pendingReportAction: (() -> Void)? = nil
    
    init() {
        let context = PersistenceController.shared.container.viewContext // fallback for preview
        _viewModel = StateObject(wrappedValue: ReportCreationViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Report Type")) {
                    Picker("Type", selection: $viewModel.selectedType) {
                        ForEach(ReportCreationViewModel.ReportType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if viewModel.selectedType == .meal {
                    Section(header: Text("Date Range")) {
                        HStack {
                            VStack(alignment: .leading) {
                                CustomDatePicker(title: "Start", date: Binding(
                                    get: { viewModel.dateRange.lowerBound },
                                    set: { viewModel.dateRange = $0...viewModel.dateRange.upperBound }
                                ))
                            }
                            VStack(alignment: .leading) {
                                CustomDatePicker(title: "End", date: Binding(
                                    get: { viewModel.dateRange.upperBound },
                                    set: { viewModel.dateRange = viewModel.dateRange.lowerBound...$0 }
                                ))
                            }
                        }
                    }
                }
                
                Section(header: Text(viewModel.selectedType == .meal ? "Select Meals" : "Select Trip")) {
                    if viewModel.selectedType == .trip {
                        Text("Select a trip below.")
                    }
                    List {
                        ForEach(viewModel.items) { item in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                    if viewModel.selectedType == .meal {
                                        if let meal = fetchMeal(for: item.id) {
                                            Text(meal.date?.formatted(date: .abbreviated, time: .omitted) ?? "")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    } else if viewModel.selectedType == .trip, let subtitle = item.subtitle {
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                if viewModel.selectedType == .meal {
                                    Image(systemName: item.isSelected ? "checkmark.square" : "square")
                                        .onTapGesture {
                                            viewModel.toggleSelection(for: item.id)
                                        }
                                } else {
                                    Image(systemName: item.isSelected ? "largecircle.fill.circle" : "circle")
                                        .onTapGesture {
                                            viewModel.toggleSelection(for: item.id)
                                        }
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                }
                
                Section {
                    Button(action: {
                        // Check if trip report and Drive is selected
                        if viewModel.selectedType == .trip,
                           let trip = viewModel.selectedTrip(context: context),
                           trip.transportType == "drive" {
                            // Show mileage prompt
                            showMileagePrompt = true
                            mileageInput = ""
                            pendingReportAction = {
                                if viewModel.generateReport(mileage: mileageInput) {
                                    dismiss()
                                }
                            }
                        } else {
                            if viewModel.generateReport(mileage: nil) {
                                dismiss()
                            }
                        }
                    }) {
                        Text("Generate Report")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Create Report")
            .alert(isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Alert(
                    title: Text("Report Generation Failed"),
                    message: Text(viewModel.errorMessage ?? "Unknown error"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showMileagePrompt) {
                VStack(spacing: 20) {
                    Text("Enter round-trip mileage for this trip:")
                        .font(.headline)
                    TextField("Mileage", text: $mileageInput)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                    HStack {
                        Button("Cancel") {
                            showMileagePrompt = false
                            pendingReportAction = nil
                        }
                        .padding()
                        Button("OK") {
                            showMileagePrompt = false
                            pendingReportAction?()
                            pendingReportAction = nil
                        }
                        .padding()
                        .disabled(mileageInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding()
                .presentationDetents([.medium])
            }
        }
    }
    
    // Add helper to fetch meal for date display
    private func fetchMeal(for itemID: UUID) -> MealItem? {
        let request: NSFetchRequest<MealItem> = MealItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", itemID as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}

extension ReportCreationViewModel {
    func selectedTrip(context: NSManagedObjectContext) -> Trip? {
        guard selectedType == .trip, let selectedID = items.first(where: { $0.isSelected })?.id else { return nil }
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", selectedID as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }
}

struct ReportCreationView_Previews: PreviewProvider {
    static var previews: some View {
        ReportCreationView()
    }
} 
