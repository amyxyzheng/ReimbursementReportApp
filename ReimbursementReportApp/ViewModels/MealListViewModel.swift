//
//  MealListViewModel.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import Foundation
import CoreData
import Combine

class MealListViewModel: ObservableObject {
    @Published var meals: [MealItem] = []
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        fetchMeals()
    }

    func fetchMeals() {
        let request: NSFetchRequest<MealItem> = MealItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MealItem.date, ascending: false)]
        do {
            meals = try context.fetch(request)
        } catch {
            print("Failed to fetch meals: \(error)")
        }
    }

    func addMeal(date: Date, occasion: String, receiptData: Data, receiptType: String) {
        let meal = MealItem(context: context)
        meal.id = UUID()
        meal.date = date
        meal.occasion = occasion
        meal.receiptData = receiptData
        meal.receiptType = receiptType

        do {
            try context.save()
            fetchMeals()
        } catch {
            print("Failed to save meal: \(error)")
        }
    }
    
    func deleteMeals(at offsets: IndexSet) {
        for index in offsets {
            let meal = meals[index]
            context.delete(meal)
        }

        do {
            try context.save()
            fetchMeals()
        } catch {
            print("Failed to delete meal: \(error)")
        }
    }
    
    func updateMeal(_ meal: MealItem,
                    newDate: Date,
                    newOccasion: String,
                    newData: Data,
                    newType: String) {
        meal.date = newDate
        meal.occasion = newOccasion
        meal.receiptData = newData
        meal.receiptType = newType

        do {
            try context.save()
            fetchMeals()
        } catch {
            print("Failed to update meal: \(error)")
        }
    }
}
