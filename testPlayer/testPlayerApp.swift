//
//  testPlayerApp.swift
//  testPlayer
//
//  Created by Edward Hill on 2023-01-13.
//

import SwiftUI

@main
struct testPlayerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
