//
//  Truncated.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 22.02.2024.
//

import Foundation

extension String {
    func truncated(to limit: Int, withTrailing trailing: String = "...") -> String {
        guard self.count > limit else { return self }
        let endIndex = self.index(self.startIndex, offsetBy: limit)
        return String(self[..<endIndex]) + trailing
    }
}
