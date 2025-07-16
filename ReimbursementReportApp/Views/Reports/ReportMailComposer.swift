import SwiftUI
import MessageUI

struct ReportMailComposer: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let zipData: Data
    let zipFilename: String
    let onDismiss: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: ReportMailComposer
        init(_ parent: ReportMailComposer) { self.parent = parent }
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true) {
                self.parent.onDismiss()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        guard MFMailComposeViewController.canSendMail() else {
            let alert = UIAlertController(title: "Mail Not Available", message: "Please set up a mail account to send reports.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.onDismiss()
            })
            return alert
        }
        let mail = MFMailComposeViewController()
        mail.setSubject(subject)
        mail.setMessageBody(body, isHTML: false)
        mail.addAttachmentData(zipData, mimeType: "application/zip", fileName: zipFilename)
        mail.mailComposeDelegate = context.coordinator
        return mail
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
} 