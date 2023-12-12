//
//  JournalListView.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 01.12.2023.
//

import SwiftUI
import RealmSwift

struct JournalListView: View {
    @ObservedResults(JournalEntry.self, sortDescriptor: SortDescriptor(keyPath: "date", ascending: false)) var journalEntries
        
    @State private var selectedEntry: JournalEntry?
    @State private var showingAddNewJournalEntry = false
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedEntry) {
                ForEach(journalEntries) { (entry: JournalEntry) in
                    NavigationLink {
                        JournalEntryView(entry: entry)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(entry.name.transformToSentenceCase())
                                .font(.headline)
                                .multilineTextAlignment(.leading)
                                .frame(height: 50)
                            Text(format(Date: entry.date))
                                .font(.system(size: 10))
                                .multilineTextAlignment(.leading)
                                .padding(.bottom, 0.0)
                                .opacity(0.5)
                        }
                        .padding(.horizontal, 15)
                    }
                }
                .onDelete(perform: { indexSet in
                    for index in indexSet {
                        let item = journalEntries[index]
                        $journalEntries.remove(item)
                    }
                })
            }
            .navigationTitle("Lumi")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showingAddNewJournalEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddNewJournalEntry, content: {
                let viewModel = JournalEntryViewModelImpl()
                let entry = JournalEntry(id: UUID(), name: "", date: Date(), body: "")

                JournalEntryView()
            })
        } detail: {
            Text("Select journal entry or create a new one")
            Button {
                showingAddNewJournalEntry.toggle()
            } label: {
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 50, height: 50, alignment: .center)
                    .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
            }
        }
    }
    
    func format(Date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: Date)
    }
}

#Preview {
    JournalListView()
        .environment(\.realm, DatabaseInteractor.RealmMockup)
}
