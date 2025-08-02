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
    
    @State private var editingExpense: MealItem? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.expenses, id: \.id) { expense in
                    Button {
                        editingExpense = expense
                    } label: {
                        ExpenseRowView(expense: expense)
                    }
                    .buttonStyle(.plain) // Prevents blue highlight
                }
                .onDelete(perform: viewModel.deleteExpenses)
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
            .sheet(item: $editingExpense) { expense in
                AddExpenseView(viewModel: viewModel, editingExpense: expense)
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
