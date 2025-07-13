//
//  AddMealView.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import SwiftUI

struct AddMealView: View {
    @Environment(\.dismiss) private var dismissAddMeal
    @ObservedObject var viewModel: MealListViewModel

    let editingMeal: MealItem?

    @State private var date: Date
    @State private var occasion: String
    @State private var imageData: Data?
    @State private var fileType: String
    @State private var pickerSource: PickerSource? = nil
    
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
                    HStack {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button(action: {
                                        pickerSource = .camera
                                    }) {
                                Label("Take Photo", systemImage: "camera")
                            }
                            .buttonStyle(.bordered)
                        }
                        Spacer()
                        Button(action: {
                                pickerSource = .photoLibrary
                            }) {
                            Label("Select Photo", systemImage: "photo")
                        }
                        .buttonStyle(.bordered)
                    }
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
            .sheet(item: $pickerSource) { source in
                ImagePicker(
                    sourceType: source.sourceType,
                    imageData: $imageData,
                    fileType: $fileType,
                    pickerSource: $pickerSource
                )
            }
        }
    }
}

enum PickerSource: Identifiable {
    case camera, photoLibrary

    var id: Int { hashValue }

    var sourceType: UIImagePickerController.SourceType {
        switch self {
        case .camera: return .camera
        case .photoLibrary: return .photoLibrary
        }
    }
}


// UIImagePickerController wrapper
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var imageData: Data?
    @Binding var fileType: String
    @Binding var pickerSource: PickerSource?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        /*
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
         */
        print("Using sourceType:", sourceType.rawValue) // 1 = camera, 0 = photo library
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.delegate = context.coordinator
            return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage,
               let data = uiImage.jpegData(compressionQuality: 0.8) {
                parent.imageData = data
                parent.fileType = "image/jpeg"
            }
            parent.pickerSource = nil
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.pickerSource = nil
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
