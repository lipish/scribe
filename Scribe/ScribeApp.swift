//
//  ScribeApp.swift
//  Scribe
//
//  Created by Scribe Team on 2024.
//

import SwiftUI
import CoreData

@main
struct ScribeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        
        Settings {
            SettingsView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}