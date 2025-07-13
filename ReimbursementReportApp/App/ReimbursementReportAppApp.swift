//
//  ReimbursementReportAppApp.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import SwiftUI

@main
struct ReimbursementReportAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext,
                             persistenceController.container.viewContext)
        }
    }
}
