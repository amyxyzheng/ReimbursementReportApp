//
//  MainTabView.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ExpenseListView().tabItem { Label("Expenses", systemImage: "creditcard") }
            TripListView().tabItem { Label("Trips", systemImage: "airplane") }
            ReportsListView().tabItem { Label("Reports", systemImage: "doc.text") }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
