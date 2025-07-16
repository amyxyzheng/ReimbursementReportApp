import SwiftUI

struct TemporaryFileData: Identifiable {
    let id = UUID()
    let data: Data
    let fileName: String
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [TemporaryFileData]
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURLs = activityItems.map { item -> URL in
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(item.fileName)
            try? item.data.write(to: tempURL)
            return tempURL
        }
        let controller = UIActivityViewController(activityItems: tempURLs, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            // Clean up temp files
            for url in tempURLs { try? FileManager.default.removeItem(at: url) }
            onDismiss()
        }
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 