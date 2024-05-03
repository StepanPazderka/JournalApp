//
//  String+cleanedUp.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 01.12.2023.
//

import Foundation

extension String {
    func cleaned() -> String {
        // Remove leading and trailing whitespaces and new lines
        let trimmedText = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Replace multiple spaces with a single space
        let singleSpacedText = trimmedText.replacingOccurrences(of: " +", with: " ", options: .regularExpression, range: nil)
        
        // Replace multiple new lines with a single new line
        let cleanText = singleSpacedText.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression, range: nil)
        
        return cleanText
    }
    
    func replacingSmileysWithEmojis() -> String {
        var newText = self
        let smileyToEmoji = [
            ":)": "🙂",
            ":(": "🙁",
            ";)": "😉",
            ":D": "😀",
            ":P": "😛",
            ":'(": "😢"
            // Add more smiley-emoji pairs here
        ]
        
        for (smiley, emoji) in smileyToEmoji {
            newText = newText.replacingOccurrences(of: smiley, with: emoji)
        }
        
        return newText
    }
    
    func cleanString() -> String {
        var modifiedString = self
        if modifiedString.hasPrefix(".") {
            modifiedString.removeFirst()
        }
        return modifiedString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
