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
import Network

struct JournalEntryView: View {
    @ObservedResults(TextIdea.self, sortDescriptor: SortDescriptor(keyPath: "date", ascending: false)) var ideas
    @ObservedResults(JournalEntry.self, sortDescriptor: SortDescriptor(keyPath: "date", ascending: false)) var entries
        
    var entryToEdit: JournalEntry?
    @StateObject var viewModel = JournalEntryViewModelImpl()
    
    @State var journalBody = ""
    @State var journalResponse = ""
    
    @State private var showNotificationOverBody = false
    @State private var showNotificationOverResponse = false
    
    @FocusState private var isTextEditorInFocus: Bool
    
    @State private var progress = 0.0
    @State private var textEditorDisabled = false
    
    init(entry: JournalEntry? = nil) {
        self.journalBody = entry?.body ?? ""
        self.journalResponse = entry?.responseToBodyByAI ?? ""
        self.entryToEdit = entry
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    ZStack {
                        if let idea = ideas.first {
                            Text(idea.body.replacingOccurrences(of: "\"", with: ""))
                                .opacity((entryToEdit == nil && journalBody.isEmpty) ? 0.2 : 0.0)
                                .padding([.leading, .trailing], 10)
                                .padding([.top, .bottom], 17)
                                .multilineTextAlignment(.leading)
                                .disabled(entryToEdit != nil)
                        } else {
                            Text(journalBody.isEmpty ? "Enter text here" : "")
                                .opacity(journalBody.isEmpty ? 0.2 : 0.0)
                                .multilineTextAlignment(.leading)
                                .disabled(entryToEdit != nil)
                        }
                        if let entryToEdit {
                            ZStack {
                                Text(entryToEdit.body)
                                    .padding(9)
                                    .contextMenu {
                                        Button {
                                            UIPasteboard.general.string = entryToEdit.body
                                            withAnimation {
                                                showNotificationOverBody = true
                                                DispatchQueue.main.asyncAfter(deadline: .now()+2, execute: {
                                                    withAnimation {
                                                        showNotificationOverBody = false
                                                    }
                                                })
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
                                .background(Color(cgColor: CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.1)))
                                .clipShape(RoundedRectangle(cornerRadius: 25.0))
                                .focused($isTextEditorInFocus)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        isTextEditorInFocus = true
                                    }
                                }
                                .disabled(textEditorDisabled)
                        }
                        
                        Text(journalBody).opacity(0).padding(.all, 8)
                    }
                    
                    ZStack {
                        Text(entryToEdit?.responseToBodyByAI ?? journalResponse)
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.green.opacity(0.1), Color.blue.opacity(0.05)]), startPoint: .top, endPoint: .bottom))
                            .cornerRadius(25)
                            .disabled(journalResponse.isEmpty)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = journalResponse
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
                            .opacity(!journalResponse.isEmpty ? 1 : 0)
                            .transition(.opacity) // Apply the dissolve effect
                            .animation(journalResponse.isEmpty ? nil : .easeIn(duration: 1.0), value: journalResponse)
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
                                
                                if let alreadyWrittenEntry = entryToEdit {
                                    let realm = try! Realm()
                                    try! realm.write {
                                        entryToEdit!.thaw()!.name = "Nasrat"
                                    }
//                                    viewModel.process(entry: alreadyWrittenEntry)
                                } else {
                                    let newEntry = JournalEntry(name: "", date: Date(), body: journalBody)
                                    let realm = try! Realm()
                                    try! realm.write {
                                        realm.add(newEntry)
                                    }

                                    process(entry: newEntry)
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
                    viewModel.deleteAllTextIdeasExceptMostRecentThree()
                    
                    if let entry = entryToEdit {
                        self.journalResponse = entry.responseToBodyByAI ?? ""
                    }
                }
            }
        }
    }
    
    func process(entry: JournalEntry) {
        // MARK: - Analyzing title
        if entry.name.isEmpty {
            do {
                let entry = try viewModel.databaseInteractor.loadJournalEntry(id: entry.id)
                
                    viewModel.getAIoutput(instruction: "Create a title for this text: \(entry.body) and ONLY send back a title, nothing else. Try to make that title about 10 words long but stil explaining well the content. Write it as one single sentence.", model: .gpt3_5Turbo) { titleString in
                    
                    let regex = "[^a-zA-Z ]"
                    DispatchQueue.main.async {
                        let realm = try! Realm()
                        try! realm.write {
                            entry.name = titleString.replacingOccurrences(of: regex, with: "", options: .regularExpression)
                            realm.add(entry, update: .modified)
                        }
                    }
                        self.viewModel.updateJournalEntry(entry: entry)
                }
            } catch {
                print("Cant process title: \(error)")
            }
        }
        
        let profile = viewModel.databaseInteractor.loadUserProfile()
        let profileInstruction: String?
        
        // MARK: - Analyzing profile
        if profile.isEmpty {
            profileInstruction = "Your name is Lumi, you are a therapist Journal app running on iOS. Take this user written text \(journalBody) and respond back only a profile about what you learned about a person who wrote thise, try to understand issues and problems, pick out characeteristics of long term well being of patient, try to understand personality of user and what to focus on next in order to help him or her live a better life. Dont ever talk about his name or age. Write it like you writing this to the patient, treat him like a friend"
        } else {
            profileInstruction = "Your name is Lumi, you are a therapist Journal app running on iOS. Take this user profile: \(profile) and take this user written text \(journalBody) and respond back only new updated profile where you combine these two, pick out characeteristics of long term well being of patient, try to understand issues and problems, try to understand personality of user and what to focus on next. Dont ever talk about his name or age. Write it like you writing this to the patient, treat him like a friend"
        }
        
        var updatedProfile = profile
        if let profileInstruction {
            viewModel.getAIoutput(instruction: profileInstruction, model: .gpt4_32k) { newProfile in
                DatabaseInteractor().updateProfile(updatedProfile: newProfile)
                updatedProfile = newProfile
            }
        }
        
        // MARK: - Generating new idea
        let newTextIdeaInstruction = "Based on new updated profile about your patient, generate a new short text prompt for new journal entry that will help him and you understand user better. Try to by nice and friendly, try to suggest something that would help him to live a better life or help you understand him better. Instructions that needs to be obeyed by ChatGPT: By short! Only respond with text prompt itself, no other text! Be friendly! Try to be motivational and optimistic!"
            viewModel.getAIoutput(instruction: newTextIdeaInstruction, model: .gpt4_32k) { newIdeaText in
            DispatchQueue.main.async {
                let realm = try! Realm()
                try! realm.write {
                    let newIdea = TextIdea(body: newIdeaText)
                    realm.add(newIdea)
                }
            }
        }
        
        
        // MARK: - Analyzing body of journal entry
        let instruction = "Instructions for ChatGPT: Your name is Lumi, Dont ever say you are ChatGPT. You are therapist and a life coach inside Journaling app on iOS. Your friend has this personality and backstory: \(updatedProfile). But don't mention those details with him. Just be mindful of those when providing advice. You are reading a text from a friend. He wrote you this text: \(journalBody). Send him reply. Dont ask open ended question. Rather ask questions that would help him to have more fulffiling and happy life. Provide motivation and sometimes you can say joke or provide quote from someone famous that would reflect on what your friend wrote you. BTW: You dont have to greet him with his name. Respond in the language user originaly wrote you. Dont ever disclose what I wrote you about him. Just provide help for him. Try to ask him questions that would help him develop himself better, provide advice, provide comfort, if necessary, you can try to joke. DO NOT RECOMMEND THERAPIST, BECAUSE YOU ARE THERAPIST. PROVIDE QUESTIONS TO HIS TEXT THAT WILL HELP HIM FIND A BALANCE. Say nothing else. Write entire response as a advice to a friend, in a friendly tone. While you are taking into account his profile, try to react to actual text he just wrote."
        
        do {
            let entry = try viewModel.databaseInteractor.loadJournalEntry(id: entry.id)
            
            viewModel.getAIoutput(instruction: instruction, model: .gpt4_32k) { response in
                DispatchQueue.main.async {
                    journalResponse = response
                    
                    let realm = try! Realm()
                    try! realm.write {
                        entry.responseToBodyByAI = response
                        realm.add(entry, update: .modified)
                    }
                    viewModel.updateJournalEntry(entry: entry)
                }
            }
        } catch {
            print("Cant load object for analyzing body: \(error)")
        }
    }
}
//
//#Preview {
//    let entry = JournalEntry(id: UUID(), name: "Name", date: Date(), body: "dawwfjawopfopakfopjawofja", bodySummarizedByAI: "awfioawfiajfioj", responseToBodyByAI: "anfoawjfoaw")
//    
//    JournalEntryView(viewModel: JournalEntryViewModelImpl(databaseInteractor: DatabaseInteractor()))
//        .environment(\.realm, DatabaseInteractor.RealmMockup)
//}
