//
//  ModelContext+existingModel.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 22.02.2024.
//

import Foundation
import SwiftData

extension ModelContext {
    func existingModel<T>(for objectID: PersistentIdentifier)
    throws -> T? where T: PersistentModel {
        if let registered: T = registeredModel(for: objectID) {
            return registered
        }
        
        let fetchDescriptor = FetchDescriptor<T>(
            predicate: #Predicate {
                $0.persistentModelID == objectID
            })
        
        return try fetch(fetchDescriptor).first
    }
}
