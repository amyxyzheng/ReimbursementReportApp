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
    @State private var showingSourceDialog = false
    @State private var pickerSource: PickerSource?
    @State private var showingDocumentPicker = false
    
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
                    CustomDatePicker(title: "Date", date: $date, displayedComponents: .date)
                    TextField("Occasion", text: $occasion)
                }
                Section(header: Text("Upload Receipt")) {
                    Button(action: { showingSourceDialog = true }) {
                        HStack {
                            Image(systemName: editingMeal != nil ? "pencil" : "plus")
                            Text(editingMeal != nil ? "Change Receipt" : "Add Receipt")
                        }
                    }
                    .confirmationDialog("Add Receipt", isPresented: $showingSourceDialog, titleVisibility: .visible) {
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
                                imageData = data
                                fileType = type
                            },
                            pickerSource: $pickerSource
                        )
                    }
                    .sheet(isPresented: $showingDocumentPicker) {
                        DocumentPicker { data, mimeType in
                            imageData = data
                            fileType = mimeType
                        }
                    }
                    if let data = imageData {
                        if let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                        } else if fileType == "application/pdf" {
                            HStack {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text("PDF Document")
                                        .font(.headline)
                                    Text("Size: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .navigationTitle(editingMeal != nil ? "Edit Meal" : "Add Meal")
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
