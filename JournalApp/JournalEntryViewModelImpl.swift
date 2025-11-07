//
//  JournalEntryViewModelImpl.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 01.12.2023.
//

import Foundation
import OpenAI
import Combine
import SwiftUI

import SwiftData

final class JournalEntryViewModelImpl: JournalViewModel {    
    @Published var showingAlert = false
    @Published var alertMessage = ""
    
    private var context: ModelContext!
    private var databaseInteractor: DatabaseInteractor!
    public let entry: JournalEntrySwiftData?
    
    init() {
        self.entry = nil
    }
    
    init(entry: JournalEntrySwiftData) {
        self.entry = entry
    }
    
    func invokeNetworkProblemAlert(error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.alertMessage = "Error: \(error.localizedDescription)"
            self?.showingAlert = true
        }
    }
    
    func process(entry: JournalEntrySwiftData) async -> JournalEntrySwiftData {
		do {
			return try await databaseInteractor.processEntry(entry: entry)
		} catch {
			alertMessage = error.localizedDescription
			showingAlert = true
			return entry
		}
    }
    
    // MARK: - Persistence helpers moved from View
    func createEntry(withBody body: String) -> JournalEntrySwiftData {
        let newEntrySwiftData = JournalEntrySwiftData(date: Date(), name: "", body: body)
        context.insert(newEntrySwiftData)
        try? context.save()
        return newEntrySwiftData
    }

    func persist(_ entry: JournalEntrySwiftData) {
        context.insert(entry)
        try? context.save()
    }
    
    func setup(context: ModelContext) {
        self.context = context
        self.databaseInteractor = DatabaseInteractor(modelContainer: context.container)
    }
}
