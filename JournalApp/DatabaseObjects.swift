//
//  DatabaseObjects.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 01.12.2023.
//

import Foundation
import RealmSwift

final class JournalEntry: Object, ObjectKeyIdentifiable, Identifiable {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var date: Date
    @Persisted var name: String
    @Persisted var body: String
    @Persisted var bodySummarizedByAI: String?
    @Persisted var responseToBodyByAI: String?
    @Persisted(originProperty: "entries") var journal: LinkingObjects<Journal>
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    required override init() {
        super.init()
    }
    
    internal init(id: UUID? = nil, name: String, date: Date, body: String, bodySummarizedByAI: String? = nil, responseToBodyByAI: String? = nil) {
        super.init()
        self.id = id?.uuidString ?? UUID().uuidString
        self.name = name
        self.date = date
        self.body = body
        self.bodySummarizedByAI = bodySummarizedByAI
        self.responseToBodyByAI = responseToBodyByAI
    }
    
//    static let mock = Self(id: UUID(), name: "Name", date: Date(), body: "Body")
}

final class TextIdea: Object, ObjectKeyIdentifiable {
    internal init(body: String = "") {
        self.body = body
    }
    
    @Persisted(primaryKey: true) var id = UUID().uuidString
    @Persisted var date = Date()
    @Persisted var body = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    required override init() {
        super.init()
    }
}

final class Journal: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id = UUID().uuidString
    @Persisted var entries = List<JournalEntry>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    required override init() {
        super.init()
    }
}

final class Profile: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id = UUID().uuidString
    @Persisted var name: String
    @Persisted var profile: String
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
