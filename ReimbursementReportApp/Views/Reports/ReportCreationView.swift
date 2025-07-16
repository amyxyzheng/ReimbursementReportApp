import SwiftUI
import CoreData

struct ReportCreationView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: ReportCreationViewModel
    @Environment(\.dismiss) private var dismiss
    
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
                                ), displayedComponents: .date)
                            }
                            VStack(alignment: .leading) {
                                CustomDatePicker(title: "End", date: Binding(
                                    get: { viewModel.dateRange.upperBound },
                                    set: { viewModel.dateRange = viewModel.dateRange.lowerBound...$0 }
                                ), displayedComponents: .date)
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
                        if viewModel.generateReport() {
                            dismiss()
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

struct ReportCreationView_Previews: PreviewProvider {
    static var previews: some View {
        ReportCreationView()
    }
} 