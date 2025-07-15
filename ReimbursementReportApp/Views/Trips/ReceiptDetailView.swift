//
//  ReceiptDetailView.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import SwiftUI

struct ReceiptDetailView: View {
    let receipt: Receipt
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                if let data = receipt.data, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                } else {
                    VStack {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Receipt image not available")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Category:")
                            .font(.headline)
                        Text(receipt.expenseCategory?.capitalized ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    
                    if let date = receipt.date {
                        HStack {
                            Text("Date:")
                                .font(.headline)
                            Text(date.formatted(.dateTime.month().day().year()))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let type = receipt.type {
                        HStack {
                            Text("Type:")
                                .font(.headline)
                            Text(type)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Receipt Detail")
        }
    }
}

#if DEBUG
import SwiftUI
import CoreData

struct ReceiptDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // Create a sample receipt
        let sampleReceipt = Receipt(context: context)
        sampleReceipt.id = UUID()
        sampleReceipt.date = Date()
        sampleReceipt.expenseCategory = "transport"
        sampleReceipt.type = "image/jpeg"
        
        return ReceiptDetailView(receipt: sampleReceipt)
            .environment(\.managedObjectContext, context)
    }
}
#endif 