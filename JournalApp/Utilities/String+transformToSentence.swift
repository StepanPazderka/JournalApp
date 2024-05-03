//
//  String+transformToSentence.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 10.12.2023.
//

import Foundation

extension String {
    func transformToSentenceCase() -> String {
        let lowercaseString = self.lowercased()
        if let firstCharacter = lowercaseString.first {
            return firstCharacter.uppercased() + lowercaseString.dropFirst()
        } else {
            return lowercaseString
        }
    }
}
