//
//  MainTabView.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 10.03.2024.
//

import SwiftUI

struct MainTabView: View {
    @State var showingNewJournalEntry = false
    @State var selectedTab: ViewType = .journal
    
    @State var previouslySelectedTab: ViewType = .journal
    
    var body: some View {
        TabView(selection: $selectedTab) {
            JournalListView()
                .tabItem { Label("Journal", systemImage: "list.dash") }
                .tag(ViewType.journal)
            EmptyView()
                .tabItem { Label("New Entry", systemImage: "plus")}
                .sheet(isPresented: $showingNewJournalEntry) {
                    JournalEntryView()
                }
                .tag(ViewType.entry)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(ViewType.journal)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .entry {
                showingNewJournalEntry = true
                selectedTab = oldValue
            } else {
                previouslySelectedTab = newValue
            }
        }
    }
}

#Preview {
    MainTabView()
}
