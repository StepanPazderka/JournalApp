//
//  JournalListView.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 01.12.2023.
//

import SwiftUI
import RealmSwift
import SwiftData

struct JournalListView: View {
    @Query(sort: \JournalEntrySwiftData.date) var journalEntriesSwiftData: [JournalEntrySwiftData]
    
    @State private var selectedEntry: JournalEntrySwiftData?
    @State private var showingAddNewJournalEntry = false
    
    @State var showingRenameDialog = false
    @State var newName = ""
    @State var selectedId: JournalEntrySwiftData?
    
    @Environment(\.modelContext) private var context
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedEntry) {
                ForEach(journalEntriesSwiftData) { (entry: JournalEntrySwiftData) in
                    NavigationLink {
                        JournalEntryView(entry: entry)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(entry.name?.transformToSentenceCase() ?? entry.body!.truncated(to: 25))
                                .font(.headline)
                                .multilineTextAlignment(.leading)
                                .frame(height: 50)
                            Text(format(Date: entry.date ?? .now))
                                .font(.system(size: 10))
                                .multilineTextAlignment(.leading)
                                .padding(.bottom, 0.0)
                                .opacity(0.5)
                        }
                        .padding(.horizontal, 15)
                        .contextMenu {
                            Button {
                                selectedId = entry
//                                selectedEntry = entry
                                if let selectedId {
                                    newName = selectedId.name ?? ""
                                }
                                showingRenameDialog = true
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                        }
                    }
                }
                .onDelete(perform: { indexSet in
                    for index in indexSet {
                        let item = journalEntriesSwiftData[index]
                        context.delete(item)
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
                JournalEntryView()
            })
            .alert("Rename entry", isPresented: $showingRenameDialog) {
                TextField("Enter entry name", text: $newName)
                Button("OK", role: .cancel) {
                    if let selectedEntry = selectedId {
                        selectedEntry.name = newName
                        context.insert(selectedEntry)
                    }
                }
            }
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
