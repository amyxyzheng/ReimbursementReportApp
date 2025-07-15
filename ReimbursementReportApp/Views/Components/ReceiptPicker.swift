//
//  ReceiptPicker.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import SwiftUI
import PhotosUI

struct ReceiptPicker: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @State private var pickerSource: PickerSource?
    let onImageSelected: (Data, String) -> Void
    
    var body: some View {
        HStack {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(action: {
                    pickerSource = .camera
                }) {
                    Label("Camera", systemImage: "camera")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            Button(action: {
                pickerSource = .photoLibrary
            }) {
                Label("Photo Library", systemImage: "photo")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.bordered)
        }
        .sheet(item: $pickerSource) { source in
            ImagePicker(
                sourceType: source.sourceType,
                onImageSelected: onImageSelected,
                pickerSource: $pickerSource
            )
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
    let onImageSelected: (Data, String) -> Void
    @Binding var pickerSource: PickerSource?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
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
                parent.onImageSelected(data, "image/jpeg")
            }
            parent.pickerSource = nil
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.pickerSource = nil
        }
    }
}

#if DEBUG
struct ReceiptPicker_Previews: PreviewProvider {
    static var previews: some View {
        ReceiptPicker(
            selectedPhotoItem: .constant(nil),
            onImageSelected: { data, type in
                print("Image selected: \(data.count) bytes, type: \(type)")
            }
        )
        .padding()
    }
}
#endif 