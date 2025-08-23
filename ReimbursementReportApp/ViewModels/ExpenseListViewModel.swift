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
    @Published var expenses: [MealItem] = []
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        fetchExpenses()
    }

    func fetchExpenses() {
        let request: NSFetchRequest<MealItem> = MealItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MealItem.date, ascending: false)]
        do {
            expenses = try context.fetch(request)
        } catch {
            print("Failed to fetch expenses: \(error)")
        }
    }

    func addExpense(date: Date, occasion: String, receiptData: Data, receiptType: String) {
        let expense = MealItem(context: context)
        expense.id = UUID()
        expense.date = date
        expense.occasion = occasion
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
    
    func deleteExpense(_ expense: MealItem) {
        context.delete(expense)
        do {
            try context.save()
            fetchExpenses()
        } catch {
            print("Failed to delete expense: \(error)")
        }
    }
    
    func toggleReimbursed(_ expense: MealItem) {
        expense.reimbursed.toggle()
        do {
            try context.save()
            fetchExpenses()
        } catch {
            print("Failed to update expense reimbursement status: \(error)")
        }
    }
    
    func updateExpense(_ expense: MealItem,
                    newDate: Date,
                    newOccasion: String,
                    newData: Data,
                    newType: String) {
        expense.date = newDate
        expense.occasion = newOccasion
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