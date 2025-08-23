import SwiftUI
import CoreData

struct ReceiptListView: View {
    let receipts: [Receipt]
    let onDeleteReceipt: (Receipt) -> Void
    
    var body: some View {
        if receipts.isEmpty {
            VStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                Text("No receipts yet")
                    .foregroundColor(.secondary)
                Text("Receipt count: \(receipts.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
        } else {
            ForEach(receipts, id: \.id) { receipt in
                NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                    HStack {
                        Image(systemName: receipt.data != nil ? "photo" : "doc.text")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(ReceiptCategory(rawValue: receipt.expenseCategory ?? "")?.displayName ?? (receipt.expenseCategory ?? "Receipt"))
                                .font(.subheadline)
                            if let date = receipt.date {
                                Text(date.formatted(.dateTime.month().day().year()))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        onDeleteReceipt(receipt)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
} 