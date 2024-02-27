//
//  DatabaseObjectsCloudKit.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 18.02.2024.
//

import Foundation
import SwiftData

@Model
class JournalEntrySwiftData {

    init(date: Date, name: String, body: String) {
        self.date = date
        self.name = name
        self.body = body
    }
    
    init(date: Date, name: String, body: String, bodySummarizedByAI: String, responseToBodyByAI: String) {
        self.date = date
        self.name = name
        self.body = body
        self.bodySummarizedByAI = bodySummarizedByAI
        self.responseToBodyByAI = responseToBodyByAI
    }
    
    var date: Date?
    var name: String?
    var body: String?
    var bodySummarizedByAI: String?
    var responseToBodyByAI: String?
}

extension JournalEntrySwiftData {
    convenience init(from entity: JournalEntry) {
        self.init(date: entity.date, name: entity.name, body: entity.body, bodySummarizedByAI: entity.bodySummarizedByAI ?? "", responseToBodyByAI: entity.responseToBodyByAI ?? "")
    }
}

@Model
class TextIdeaSwiftData {
    internal init(body: String = "") {
        self.body = body
    }
    
    var date = Date()
    var body = ""
}
