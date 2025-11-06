//
//  NetworkInteractor.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 14.12.2023.
//

import Foundation

protocol NetworkInteractor {    
    static var shared: Self { get }
    
    func getAIoutput(instruction: String) async -> Result<String, Error>
}
