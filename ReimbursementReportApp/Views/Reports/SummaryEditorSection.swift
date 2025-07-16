import SwiftUI

struct SummaryEditorSection: View {
    @Binding var summary: String
    @Binding var isEditing: Bool
    let onSave: () -> Void
    let placeholder: String
    
    var body: some View {
        if isEditing {
            VStack(alignment: .leading) {
                TextEditor(text: $summary)
                    .frame(minHeight: 120)
                Button("Save") {
                    onSave()
                    isEditing = false
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
        } else {
            VStack(alignment: .leading) {
                Text(summary.isEmpty ? placeholder : summary)
                    .frame(minHeight: 120, alignment: .topLeading)
                Button("Edit") {
                    isEditing = true
                }
                .buttonStyle(.bordered)
                .padding(.top, 4)
            }
        }
    }
} 