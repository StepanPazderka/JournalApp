//
//  ContentView.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 30.11.2023.
//

import SwiftUI
import OpenAI
import Combine
import RealmSwift
import SwiftData

struct JournalEntryView: View {
    @Query(sort: \JournalEntrySwiftData.date) var entriesSwiftData: [JournalEntrySwiftData]
    @Query(sort: \TextIdeaSwiftData.date) var ideasSwiftData: [TextIdeaSwiftData]
            
    var entryToEdit: JournalEntrySwiftData?
    @StateObject var viewModel = JournalEntryViewModelImpl()
    
    @State var journalBody = ""
    @State var journalResponse = ""
    
    @State private var showNotificationOverBody = false
    @State private var showNotificationOverResponse = false
    
    @FocusState private var isTextEditorInFocus: Bool
    
    @State private var progress = 0.0
    @State private var textEditorDisabled = false
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var context
    
    @State private var cancellables = Set<AnyCancellable>()
        
    init(entry: JournalEntrySwiftData? = nil) {
        self.journalBody = entry?.body ?? ""
        self.journalResponse = entry?.responseToBodyByAI ?? ""
        self.entryToEdit = entry
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    ZStack {
                        if entryToEdit == nil || journalBody.isEmpty {
                            if let idea = ideasSwiftData.randomElement() {
                                if journalBody.isEmpty {
                                    Text(idea.body.replacingOccurrences(of: "\"", with: ""))
                                        .opacity((entryToEdit == nil && journalBody.isEmpty) ? 0.2 : 0.0)
                                        .padding(17)
                                        .multilineTextAlignment(.leading)
                                        .disabled(entryToEdit != nil)
                                }
                            } else {
                                Text(journalBody.isEmpty || entryToEdit != nil ? "Enter text here" : "")
                                    .opacity((entryToEdit == nil && journalBody.isEmpty) ? 0.2 : 0.0)
                                    .multilineTextAlignment(.leading)
                                    .disabled(!journalBody.isEmpty)
                            }
                        }
                        if let entryToEdit {
                            ZStack {
                                Text(entryToEdit.body ?? "")
                                    .padding(9)
                                    .contextMenu {
                                        Button {
                                            #if os(macOS)
                                            NSPasteboard.general.writeObjects([entryToEdit.body! as NSString])
                                            #else
                                            UIPasteboard.general.string = entryToEdit.body
                                            #endif
                                            withAnimation {
                                                showNotificationOverBody = true
                                                DispatchQueue.main.asyncAfter(deadline: .now()+2) {
                                                    withAnimation {
                                                        showNotificationOverBody = false
                                                    }
                                                }
                                            }
                                        } label: {
                                            Label("Copy to clipboard", systemImage: "doc.on.doc")
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                if showNotificationOverBody {
                                    Text("Copied into clipboard")
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                        .opacity(showNotificationOverBody ? 1 : 0) // Apply opacity animation
                                        .transition(.opacity) // Fade in and out
                                }
                            }
                        } else {
                            TextEditor(text: $journalBody)
                                .frame(minHeight: 40)
                                .padding(9)
                                .scrollContentBackground(.hidden)
                                .background(colorScheme == .light ? Color.black.opacity(0.1) : Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 25.0))
                                .focused($isTextEditorInFocus)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        isTextEditorInFocus = true
                                    }
                                }
                                .disabled(textEditorDisabled)
                        }
                        
                        Text(journalBody)
                            .opacity(0)
                            .padding(.all, 8)
                    }
                    
                    ZStack {
                        Text(entryToEdit?.responseToBodyByAI ?? journalResponse)
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.green.opacity(0.1), Color.blue.opacity(0.05)]), startPoint: .top, endPoint: .bottom))
                            .cornerRadius(25)
                            .disabled(journalResponse.isEmpty)
                            .contextMenu {
                                Button {
                                    #if os(macOS)
                                    NSPasteboard.general.writeObjects([entryToEdit!.responseToBodyByAI! as NSString])
                                    #else
                                    UIPasteboard.general.string = entryToEdit?.responseToBodyByAI
                                    #endif
                                    withAnimation {
                                        showNotificationOverResponse = true
                                        DispatchQueue.main.asyncAfter(deadline: .now()+2, execute: {
                                            withAnimation {
                                                showNotificationOverResponse = false
                                            }
                                        })
                                    }
                                } label: {
                                    Label("Copy to clipboard", systemImage: "doc.on.doc")
                                }
                            }
                            .opacity(journalResponse.isEmpty ? 0 : 1)
                            .transition(.opacity) // Apply the dissolve effect
                            .animation(!journalResponse.isEmpty ? nil : .easeIn(duration: 0.3), value: self.journalResponse)
                            .lineLimit(nil)
                        if showNotificationOverResponse {
                            Text("Copied into clipboard")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .opacity(showNotificationOverResponse ? 1 : 0) // Apply opacity animation
                                .transition(.opacity) // Fade in and out
                        }
                        ProgressView(value: progress)
                            .progressViewStyle(.circular)
                            .hidden(!journalResponse.isEmpty || progress == 0)
                        
                        Spacer()
                        if journalResponse.isEmpty {
                            Button("Save") {
                                textEditorDisabled = true
                                progress = 0.1
                                Task {
                                    if let alreadyWrittenEntry = entryToEdit {
                                        let result = await viewModel.process(entry: alreadyWrittenEntry)
                                        self.journalResponse = result.responseToBodyByAI ?? ""
                                    } else {
                                        let newEntrySwiftData = JournalEntrySwiftData(date: Date(), name: "", body: journalBody)
                                        context.insert(newEntrySwiftData)
                                        try? context.save()
                                        print(newEntrySwiftData)
                                        
                                        let result = await viewModel.process(entry: newEntrySwiftData)
                                        self.journalResponse = result.responseToBodyByAI ?? ""

                                        print("ID of new swift data journal entry: \(newEntrySwiftData.id)")
                                    }
                                }
                                progress = 1.0
                            }
                            .frame(height: 50)
                            .hidden(!journalResponse.isEmpty || progress > 0)
                        }
                    }
                }
                .padding(20)
                .onAppear {
                    viewModel.setup(context: self.context)
                    
                    if let filteredEntry = self.entriesSwiftData.first(where: { $0.date == entryToEdit?.date }) {
                        self.journalResponse = filteredEntry.responseToBodyByAI ?? ""
                    }
                    
                    viewModel.$showingAlert.sink { value in
                        self.progress = 0.0
                    }.store(in: &cancellables)
                }
                .alert(viewModel.alertMessage, isPresented: $viewModel.showingAlert) {
                    Button("OK", role: .cancel) { }
                }
            }
        }
    }
}
//
//#Preview {
//    let previewEntry = JournalEntry(id: UUID(), name: "Name", date: Date(), body: "Today was tougher than usual. I felt overwhelmed by the smallest tasks at work and at home. It's like a heavy cloud is hanging over me, making it hard to see the good in my day. I noticed I'm more irritable lately, snapping at my partner over trivial things. I'm also struggling to sleep well, which just adds to the feeling of being drained. I know I should be more positive, but it's just so hard right now.", responseToBodyByAI: "Thank you for sharing your feelings so openly in your journal. It's clear you're going through a challenging time. Feeling overwhelmed and experiencing changes in mood and sleep are significant, and it's important to acknowledge these feelings rather than dismissing them. \n\nFirstly, it's okay not to feel positive all the time. Emotions, even the difficult ones, are part of our human experience and provide us with valuable information about our needs. Your irritability and fatigue suggest that you might be needing more self-care or rest. \n\n I encourage you to explore some small, manageable steps that can help you cope with these feelings. This might include setting aside some time for relaxation, engaging in activities you enjoy, or practicing mindfulness to stay grounded in the present moment.\n\nRemember, it's not about removing the cloud but learning how to walk in the rain with an umbrella. We'll continue to work together to find strategies that help you manage these feelings and improve your overall well-being.")
//    JournalEntryView(entry: JournalEntrySwiftData(from: previewEntry))
//}

//#Preview {
//    JournalEntryView()
//}
