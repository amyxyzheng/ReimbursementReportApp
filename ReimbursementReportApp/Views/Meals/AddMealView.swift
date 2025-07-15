//
//  AddMealView.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import SwiftUI
import PhotosUI

struct AddMealView: View {
    @Environment(\.dismiss) private var dismissAddMeal
    @ObservedObject var viewModel: MealListViewModel

    let editingMeal: MealItem?

    @State private var date: Date
    @State private var occasion: String
    @State private var imageData: Data?
    @State private var fileType: String
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    init(viewModel: MealListViewModel, editingMeal: MealItem? = nil) {
        self.viewModel = viewModel
        self.editingMeal = editingMeal

        _date = State(initialValue: editingMeal?.date ?? Date())
        _occasion = State(initialValue: editingMeal?.occasion ?? "")
        _imageData = State(initialValue: editingMeal?.receiptData)
        _fileType = State(initialValue: editingMeal?.receiptType ?? "image/jpeg")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Date & Occasion")) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Occasion", text: $occasion)
                }
                Section(header: Text("Upload Receipt")) {
                    ReceiptPicker(
                        selectedPhotoItem: $selectedPhotoItem,
                        onImageSelected: { data, type in
                            imageData = data
                            fileType = type
                        }
                    )
                    if let data = imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                    }
                }
            }
            .navigationTitle("Add Meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismissAddMeal()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                    guard let data = imageData, !occasion.isEmpty else { return }

                        if let editingMeal = editingMeal {
                            viewModel.updateMeal(editingMeal,
                                                 newDate: date,
                                                 newOccasion: occasion,
                                                 newData: data,
                                                 newType: fileType)
                        } else {
                            viewModel.addMeal(date: date,
                                              occasion: occasion,
                                              receiptData: data,
                                              receiptType: fileType)
                        }

                        dismissAddMeal()
                    }
                }
            }
        }
    }
}

#if DEBUG
struct AddMealView_Previews: PreviewProvider {
    static var previews: some View {
        AddMealView(viewModel: {
            let vm = MealListViewModel(context: PersistenceController.preview.container.viewContext)
            return vm
        }())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
#endif
