//
//  MainTabView.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 10.03.2024.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            JournalListView()
                .tabItem { Label("Journal", systemImage: "list.dash") }
            JournalEntryView()
                .tabItem { Label("New Entry", systemImage: "plus")}
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
    }
}

#Preview {
    MainTabView()
}
