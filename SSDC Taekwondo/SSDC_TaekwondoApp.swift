//
//  SSDC_TaekwondoApp.swift
//  SSDC Taekwondo
//
//  Created by Ayman Maklad on 24/04/2026.
//

import SwiftUI
import SwiftData

@main
struct SSDC_TaekwondoApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
