//
//  JournalAppApp.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 30.11.2023.
//

import SwiftUI
import RealmSwift
import SwiftData

@main
struct JournalApp: SwiftUI.App {    
    let container: ModelContainer = {
        let storeURL = URL.documentsDirectory.appending(path: "database.sqlite")
        print("Store URL: \(storeURL)")
        let schema = Schema([JournalEntrySwiftData.self, ProfileSwiftData.self, TextIdeaSwiftData.self])
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        let container = try! ModelContainer(for: schema, configurations: configuration)
        return container
    }()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                JournalListView()
                    .tabItem { Label("Journal", systemImage: "list.dash") }
                    .overlay(alignment: .top) {
                        Color.clear // Or any view or color
                            .background(.regularMaterial) // I put clear here because I prefer to put a blur in this case. This modifier and the material it contains are optional.
                            .ignoresSafeArea(edges: .top)
                            .frame(height: 0) // This will constrain the overlay to only go above the top safe area and not under.
                    }
                ProfileView()
                    .tabItem { Label("Profile", systemImage: "person.fill") }
            }
        }
        .modelContainer(container)
    }
}
