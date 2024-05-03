//
//  ReadFirstLineOfTextfile.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 03.05.2024.
//

import Foundation

func readFirstLineOfFileInBundle(fileName: String, fileType: String) -> String? {
	if let path = Bundle.main.path(forResource: fileName, ofType: fileType) {
		do {
			let content = try String(contentsOfFile: path, encoding: .utf8)
			return content.components(separatedBy: "\n").first
		} catch {
			print("Error reading file: \(error)")
			return nil
		}
	} else {
		print("File not found in bundle.")
		return nil
	}
}
