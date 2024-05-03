//
//  View+hidden.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 04.12.2023.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder public func hidden(_ shouldHide: Bool) -> some View {
        switch shouldHide {
        case true: self.hidden()
        case false: self
        }
    }
}
