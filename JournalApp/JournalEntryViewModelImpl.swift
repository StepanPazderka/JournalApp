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
import SwiftUI

import SwiftData

final class JournalEntryViewModelImpl: JournalViewModel {
    private var networkInteractor: any NetworkInteractor = NetworkInteractorImpl.shared
    
    @Published var showingAlert = false
    @Published var alertMessage = ""
    
    public var context: ModelContext!
    private var databaseInteractor: DatabaseInteractor!
    public let entry: JournalEntry?
    
    init() {
        self.entry = nil
    }
    
    init(entry: JournalEntry) {
        self.entry = entry
    }
            
    func updateJournalEntry(entry: JournalEntry) {
        DispatchQueue.main.async {
            let realm = try? Realm()
            try! realm?.write {
                realm?.add(entry, update: .modified)
            }
        }
    }
    
    func invokeNetworkProblemAlert(error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.alertMessage = "Error: \(error.localizedDescription)"
            self?.showingAlert = true
        }
    }
    
    func deleteAllTextIdeasExceptMostRecentThree() {
        let realm = try! Realm()

        try! realm.write {
            let allTextIdeas = realm.objects(TextIdea.self).sorted(byKeyPath: "date", ascending: false)

            if allTextIdeas.count > 5 {
                let textIdeasToDelete = allTextIdeas.dropFirst(5)

                realm.delete(Array(textIdeasToDelete))
            }
        }
    }
    
    func process(entry: JournalEntrySwiftData) async {
        await databaseInteractor.processEntry(entry: entry)
    }
    
    func setup(context: ModelContext) {
        self.context = context
        self.databaseInteractor = DatabaseInteractor(modelContainer: context.container)
    }
}
