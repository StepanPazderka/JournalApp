//
//  MainTabView.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 10.03.2024.
//

import SwiftUI

struct MainTabView: View {
    @State var showingNewJournalEntry = false
    @State var selectedTab: Section = .journal
    @State var previouslySelectedTab: Section = .journal
    
    var body: some View {
        TabView(selection: $selectedTab) {
            JournalListView()
                .tabItem { Label("Journal", systemImage: "list.dash") }
                .tag(Section.journal)
            EmptyView()
                .tabItem { Label("New Entry", systemImage: "plus")}
                .sheet(isPresented: $showingNewJournalEntry) {
                    JournalEntryView()
                }
                .tag(Section.entry)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(Section.journal)
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
