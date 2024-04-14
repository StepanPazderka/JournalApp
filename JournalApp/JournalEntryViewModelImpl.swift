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
    private var networkInteractor: any NetworkInteractor = NetworkInteractorImpl.shared
    
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
        return await databaseInteractor.processEntry(entry: entry)
    }
    
    func setup(context: ModelContext) {
        self.context = context
        self.databaseInteractor = DatabaseInteractor(modelContainer: context.container)
    }
}
