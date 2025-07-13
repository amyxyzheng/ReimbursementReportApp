//
//  MealListView.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import SwiftUI

struct MealListView: View {
    @StateObject var viewModel = MealListViewModel()
    @State private var showingAddMeal = false
    
    @State private var editingMeal: MealItem? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.meals, id: \.id) { meal in
                    Button {
                        editingMeal = meal
                    } label: {
                        MealRowView(meal: meal)
                    }
                    .buttonStyle(.plain) // Prevents blue highlight
                }
                .onDelete(perform: viewModel.deleteMeals)
            }
            .navigationTitle("Meals")
            .toolbar {
                Button(action: { showingAddMeal = true }) {
                    Label("Add Meal", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealView(viewModel: viewModel)
            }
            .sheet(item: $editingMeal) { meal in
                AddMealView(viewModel: viewModel, editingMeal: meal)
            }
        }
    }
}

#if DEBUG
struct MealListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        return MealListView()
            .environment(\.managedObjectContext, context)
    }
}
#endif
