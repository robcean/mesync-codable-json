//
//  meSyncApp.swift
//  meSync
//
//  Created by Brandon Cean on 6/13/25.
//

import SwiftUI
import SwiftData

@main
struct meSyncApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TaskData.self,
            HabitData.self,
        ])
        
        // Por ahora usamos memoria para que funcione
        // TODO: Habilitar persistencia después de resolver problemas de migración
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

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
