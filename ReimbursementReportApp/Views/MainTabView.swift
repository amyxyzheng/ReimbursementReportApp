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
            MealListView().tabItem { Label("Meals", systemImage: "fork.knife") }
            TripListView().tabItem { Label("Trips", systemImage: "airplane") }
            //ReportView().tabItem { Label("Report", systemImage: "doc.text") }
        }
    }
}
