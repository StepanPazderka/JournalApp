//
//  JournalAppApp.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 30.11.2023.
//

import SwiftUI
import RealmSwift

@main
struct JournalApp: SwiftUI.App {
    
    var body: some Scene {
        WindowGroup {
            TabView {
                JournalListView()
                    .environment(\.realm, DatabaseInteractor.productionRealm)
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
    }
}
