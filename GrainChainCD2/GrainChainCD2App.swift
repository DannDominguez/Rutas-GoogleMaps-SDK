//
//  GrainChainCD2App.swift
//  GrainChainCD2
//
//  Created by Daniela Ciciliano on 06/05/24.
//

import SwiftUI

@main
struct GrainChainCD2App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
