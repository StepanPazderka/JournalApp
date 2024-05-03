//
//  DateFormatter.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 14.04.2024.
//

import Foundation

func format(Date: Date) -> String {
	let formatter = DateFormatter()
	formatter.dateStyle = .medium
	formatter.timeStyle = .short
	return formatter.string(from: Date)
}
