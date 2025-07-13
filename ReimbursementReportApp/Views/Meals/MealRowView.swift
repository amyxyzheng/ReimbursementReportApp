//
//  MealRowView.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import SwiftUI

struct MealRowView: View {
    var meal: MealItem

    var body: some View {
        VStack(alignment: .leading) {
            Text(meal.occasion ?? "(No Occasion)")
                .font(.headline)
            if let date = meal.date {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

#if DEBUG
struct MealRowView_Previews: PreviewProvider {
    static var previews: some View {
        MealRowView(meal: {
            let m = MealItem(context: PersistenceController.preview.container.viewContext)
            m.id = UUID()
            m.date = Date()
            m.occasion = "Team Lunch"
            return m
        }())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
#endif
