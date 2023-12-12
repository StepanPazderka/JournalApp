//
//  JournalEntryViewModelMock.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 01.12.2023.
//

import Foundation

class JournalEntryViewModelMock: JournalViewModel {
    @Published var text: String = "Just some random text"
    @Published var outputText: String = "Its fantastic you made yourself happy. I am proud of you. Its fantastic you made yourself happy. I am proud of you. Its fantastic you made yourself happy. I am proud of you."
    
    func send(text: String, completion: @escaping (String) -> Void) {
        completion("Some text")
    }
}
