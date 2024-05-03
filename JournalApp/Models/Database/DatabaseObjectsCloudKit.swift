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
    var date: Date?
    var name: String?
    var body: String?
    var archived: Bool?
    var bodySummarizedByAI: String?
    var responseToBodyByAI: String?
    
    init(date: Date, name: String, body: String, archived: Bool = false) {
        self.date = date
        self.name = name
        self.body = body
        self.archived = archived
    }
    
    init(date: Date, name: String, body: String, bodySummarizedByAI: String, responseToBodyByAI: String) {
        self.date = date
        self.name = name
        self.body = body
        self.bodySummarizedByAI = bodySummarizedByAI
        self.responseToBodyByAI = responseToBodyByAI
    }
}

@Model
class TextIdeaSwiftData {
    var date = Date()
    var body = ""

    internal init(body: String = "") {
        self.body = body
    }
}

@Model
class ProfileSwiftData {
    var name: String?
    var profile: String?
    
    init(name: String, profile: String) {
        self.name = name
        self.profile = profile
    }
}
