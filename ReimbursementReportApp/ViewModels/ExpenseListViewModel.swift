//
//  ExpenseListViewModel.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import Foundation
import CoreData
import Combine

class ExpenseListViewModel: ObservableObject {
    @Published var expenses: [ExpenseItem] = []
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        fetchExpenses()
    }

    func fetchExpenses() {
        let request: NSFetchRequest<ExpenseItem> = ExpenseItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExpenseItem.date, ascending: false)]
        do {
            expenses = try context.fetch(request)
        } catch {
            print("Failed to fetch expenses: \(error)")
        }
    }

    func addExpense(date: Date, memo: String, category: String = "meal", receiptData: Data, receiptType: String) {
        let expense = ExpenseItem(context: context)
        expense.id = UUID()
        expense.date = date
        expense.memo = memo
        expense.category = category
        expense.receiptData = receiptData
        expense.receiptType = receiptType

        do {
            try context.save()
            fetchExpenses()
        } catch {
            print("Failed to save expense: \(error)")
        }
    }
    
    func deleteExpenses(at offsets: IndexSet) {
        for index in offsets {
            let expense = expenses[index]
            context.delete(expense)
        }

        do {
            try context.save()
            fetchExpenses()
        } catch {
            print("Failed to delete expense: \(error)")
        }
    }
    
    func deleteExpense(_ expense: ExpenseItem) {
        context.delete(expense)
        do {
            try context.save()
            fetchExpenses()
        } catch {
            print("Failed to delete expense: \(error)")
        }
    }
    
    func toggleReimbursed(_ expense: ExpenseItem) {
        expense.reimbursed.toggle()
        do {
            try context.save()
            fetchExpenses()
        } catch {
            print("Failed to update expense reimbursement status: \(error)")
        }
    }
    
    func updateExpense(_ expense: ExpenseItem,
                    newDate: Date,
                    newMemo: String,
                    newCategory: String,
                    newData: Data,
                    newType: String) {
        expense.date = newDate
        expense.memo = newMemo
        expense.category = newCategory
        expense.receiptData = newData
        expense.receiptType = newType

        do {
            try context.save()
            fetchExpenses()
        } catch {
            print("Failed to update expense: \(error)")
        }
    }
} 