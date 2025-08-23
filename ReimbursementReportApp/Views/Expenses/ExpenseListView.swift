//
//  ExpenseListView.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import SwiftUI

struct ExpenseListView: View {
    @StateObject var viewModel = ExpenseListViewModel()
    @State private var showingAddExpense = false

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.expenses, id: \.id) { expense in
                    NavigationLink(destination: AddExpenseView(viewModel: viewModel, editingExpense: expense)) {
                        ExpenseRowView(expense: expense)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deleteExpense(expense)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            viewModel.toggleReimbursed(expense)
                        } label: {
                            Label(expense.reimbursed ? "Mark Unreimbursed" : "Mark Reimbursed", 
                                  systemImage: expense.reimbursed ? "xmark.circle" : "checkmark.circle")
                        }
                        .tint(expense.reimbursed ? .orange : .green)
                    }
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                Button(action: { showingAddExpense = true }) {
                    Label("Add Expense", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(viewModel: viewModel)
            }
        }
    }
}

#if DEBUG
struct ExpenseListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        return ExpenseListView()
            .environment(\.managedObjectContext, context)
    }
}
#endif
