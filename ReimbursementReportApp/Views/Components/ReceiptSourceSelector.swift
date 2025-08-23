import SwiftUI
import PhotosUI

struct ReceiptSourceSelector: View {
    @Binding var showingSourceDialog: Bool
    @Binding var pickerSource: PickerSource?
    @Binding var showingDocumentPicker: Bool
    
    let onImageSelected: (Data, String) -> Void
    let onDocumentSelected: (Data, String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Receipts").font(.headline)
                Spacer()
                Button("Add Receipt") {
                    showingSourceDialog = true
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .cornerRadius(6)
            }
        }
        .confirmationDialog("Add Receipt", isPresented: $showingSourceDialog, titleVisibility: .visible) {
            Button("Camera") {
                pickerSource = .camera
            }
            Button("Photo Library") {
                pickerSource = .photoLibrary
            }
            Button("PDF File") {
                showingDocumentPicker = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(item: $pickerSource) { source in
            ImagePicker(
                sourceType: source.sourceType,
                onImageSelected: onImageSelected,
                pickerSource: $pickerSource
            )
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(onDocumentPicked: onDocumentSelected)
        }
    }
} 