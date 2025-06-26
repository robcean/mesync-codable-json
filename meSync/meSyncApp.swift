//
//  meSyncApp.swift
//  meSync
//
//  Created by Brandon Cean on 6/13/25.
//

import SwiftUI

@main
struct meSyncApp: App {
    @StateObject private var dataManager = DataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
    }
}
