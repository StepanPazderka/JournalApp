//
//  JournalListView.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 01.12.2023.
//

import SwiftUI
import SwiftData

struct JournalListView: View {
    @Environment(\.modelContext) private var context
    
    @Query(filter: #Predicate<JournalEntrySwiftData> { journalEntry in
        return !(journalEntry.archived ?? false)
    }, sort: \JournalEntrySwiftData.date, order: .reverse) var journalEntriesSwiftData: [JournalEntrySwiftData]
    
    @Query(filter: #Predicate<JournalEntrySwiftData> { journalEntry in
        return (journalEntry.archived ?? false)
    }, sort: \JournalEntrySwiftData.date, order: .reverse) var deletedJournalEntriesSwiftData: [JournalEntrySwiftData]
    
    var entriesForView: [JournalEntrySwiftData] {
        if showingDeletedPosts {
            return deletedJournalEntriesSwiftData
        } else {
            return journalEntriesSwiftData
        }
    }
    
    @State var showingRenameDialog = false
    @State var showingDeletedPosts = false
    
    @State private var showingAddNewJournalEntry = false
    
    @State var nameForRenaming = ""
    
    @State private var showingDeletedPostsBar = false
    private var archivedPostsBarHeight: CGFloat {
        deletedJournalEntriesSwiftData.isEmpty ? 0.0 : 50.0
    }
    
	@State private var journalEntryForRenaming: JournalEntrySwiftData?
    @State private var selectedJournalEntryID: JournalEntrySwiftData?
    
    var body: some View {
        NavigationSplitView {
            List(entriesForView, selection: $selectedJournalEntryID) { entry in
                NavigationLink(destination: {
                    JournalEntryView(entry: entry)
                        .navigationTitle(entry.name ?? "")
                }) {
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
                }
                .padding(.horizontal, 15)
                .contextMenu {
                    Button {
						journalEntryForRenaming = entry
						nameForRenaming = journalEntryForRenaming?.name ?? ""
						showingRenameDialog = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                }
                .swipeActions(edge: .trailing) {
                    if !showingDeletedPosts {
                        Button(role: .destructive) {
                            entry.archived = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } else {
						Button(role: .destructive) {
							context.delete(entry)
							if deletedJournalEntriesSwiftData.isEmpty {
								showingDeletedPosts = false
							}
						} label: {
							Label("Delete", systemImage: "trash")
						}
                        Button {
                            entry.archived = false
                            if archivedPostsBarHeight == 0 {
                                showingDeletedPosts = false
                            }
                        } label: {
                            Label("Revert", systemImage: "arrow.uturn.backward")
                        }
                    }
                }
            }
            .onChange(of: showingDeletedPosts, { oldValue, newValue in
                showingDeletedPostsBar = newValue
            })
            .navigationTitle(showingDeletedPosts ? "Deleted posts" : "Journal")
            .sheet(isPresented: $showingAddNewJournalEntry, content: {
                JournalEntryView()
            })
            .overlay {
                if entriesForView.isEmpty {
                    VStack {
                        if showingDeletedPosts {
                            Text("No deleted entries")
                        } else {
                            Text("No journal entries")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onAppear {
                if !deletedJournalEntriesSwiftData.isEmpty {
                    withAnimation {
                        showingDeletedPostsBar = true
                    }
                }
                
            }
            .overlay(alignment: .bottom) {
                Button {
                    showingDeletedPosts.toggle()
                } label: {
                    HStack {
                        if !showingDeletedPosts {
                            Image(systemName: "trash")
                            Text("Deleted posts")
                        } else {
                            Image(systemName: "list.bullet")
                            Text("Journal entries")
                        }
                    }
                    .padding([.top, .bottom], 10)
                }
                .frame(height: archivedPostsBarHeight)
                .animation(.easeInOut(duration: 0.5), value: archivedPostsBarHeight)
                .opacity(!deletedJournalEntriesSwiftData.isEmpty || showingDeletedPosts ? 1 : 0)
            }
            .navigationDestination(for: JournalEntrySwiftData.self) { entry in
                JournalEntryView(entry: entry)
            }
			.alert("Rename entry", isPresented: $showingRenameDialog) {
				TextField("Enter entry name", text: $nameForRenaming)
				Button("OK", role: .none) {
					if let journalEntryForRenaming {
						withAnimation {
							journalEntryForRenaming.name = nameForRenaming
							context.insert(journalEntryForRenaming)
						}
					}
				}
				Button("Cancel", role: .cancel) {
					showingRenameDialog = false
				}
			}
        }
        detail: {
            if let selectedJournalEntryID {
                JournalEntryView(entry: selectedJournalEntryID)
            } else {
                Text("Select journal entry or create a new one")
                Button {
                    showingAddNewJournalEntry.toggle()
                } label: {
                    Image(systemName: "plus")
                        .resizable()
                        .frame(width: 50, height: 50, alignment: .center)
                        .padding([.top], 20)
                }
            }
        }
    }
}

#Preview {
    JournalListView()
        .modelContainer(DatabaseInteractorMock.mockContainer())
}
