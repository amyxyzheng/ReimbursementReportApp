//
//  ExpenseRowView.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import SwiftUI

struct ExpenseRowView: View {
    var expense: MealItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(expense.occasion ?? "(No Occasion)")
                        .font(.headline)
                        .foregroundColor(expense.reimbursed ? .secondary : .primary)
                    
                    if expense.reimbursed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                if let date = expense.date {
                    Text(date.formatted(.dateTime.month().day().year()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(expense.reimbursed ? 0.6 : 1.0)
    }
}

#if DEBUG
import SwiftUI
import CoreData

struct ExpenseRowView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseRowView(expense: {
            let m = MealItem(context: PersistenceController.preview.container.viewContext)
            m.occasion = "Sample Expense"
            m.date = Date()
            return m
        }())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
#endif
