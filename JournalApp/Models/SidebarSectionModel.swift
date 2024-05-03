//
//  SidebarSectionModel.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 10.03.2024.
//

import Foundation

enum SidebarSectionType: CaseIterable {
    case journalEntries
    case deletedEntries
    case profileScreen
}

struct SidebarSectionModel: Identifiable, Hashable {
    var id: SidebarSectionType
    var iconName: String
    var text: String
}
