//
//  JournalEntryViewModelImpl.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 01.12.2023.
//

import Foundation
import OpenAI
import Combine
import RealmSwift

@MainActor final class JournalEntryViewModelImpl: JournalViewModel {
    
    public let databaseInteractor: DatabaseInteractor
    public let entry: JournalEntry?
    
    init() {
        self.databaseInteractor = DatabaseInteractor()
        self.entry = nil
        setup()
    }
    
    init(entry: JournalEntry) {
        self.databaseInteractor = DatabaseInteractor()
        self.entry = entry
        setup()
    }
        
    private var client: OpenAI?
    
    func setup() {
        client = OpenAI(configuration: OpenAI.Configuration(token: "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"))
    }
    
    func updateJournalEntry(entry: JournalEntry) {
        DispatchQueue.main.async {
            let realm = try? Realm()
            try! realm?.write {
                realm?.add(entry, update: .modified)
            }
        }
    }
    
    // MARK: - Function for calling API service
    func getAIoutput(instruction: String, model: Model, completion: @escaping (String) -> Void) {
        let chat = Chat(role: .assistant, content: instruction, name: "Lumi")
        let chatQuery = ChatQuery(model: .gpt3_5Turbo_16k_0613, messages: [chat])
        
        client?.chats(query: chatQuery, completion: { result in
            switch result {
            case .success(let results):
                let output = results.choices.first?.message.content ?? ""
                completion(output.cleaned().replacingSmileysWithEmojis().cleanString())
            case .failure(let error):
                print(error.localizedDescription)
            }
        })
    }
    
    func deleteAllTextIdeasExceptMostRecentThree() {
        let realm = try! Realm()

        try! realm.write {
            let allTextIdeas = realm.objects(TextIdea.self).sorted(byKeyPath: "date", ascending: false)

            if allTextIdeas.count > 3 {
                let textIdeasToDelete = allTextIdeas.dropFirst(3)

                realm.delete(Array(textIdeasToDelete))
            }
        }
    }
}
