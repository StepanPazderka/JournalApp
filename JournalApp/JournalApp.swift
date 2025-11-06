//
//  JournalAppApp.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 30.11.2023.
//

import SwiftUI
import SwiftData
#if !os(macOS)
import IQKeyboardManagerSwift
#endif

@main
@MainActor
struct JournalApp: SwiftUI.App {
    let container: ModelContainer
    
    init() {
        if CommandLine.arguments.contains("--demo-db") {
            self.container = DatabaseInteractorMock.mockContainer()
        } else {
            let storeURL = URL.documentsDirectory.appending(path: "database.sqlite")
            let schema = Schema([JournalEntrySwiftData.self, ProfileSwiftData.self, TextIdeaSwiftData.self])
            let configuration = ModelConfiguration(schema: schema, url: storeURL)
            self.container = try! ModelContainer(for: schema, configurations: configuration)
        }
    }
    
    var body: some Scene {
		let databaseInteractor = DatabaseInteractor(modelContainer: container)
		
        WindowGroup {
            MainTabView()
                .onAppear {
#if !os(macOS)
                    IQKeyboardManager.shared.enable = true
#endif
                }
        }
        .modelContainer(container)
		.environmentObject(databaseInteractor)
    }
}
