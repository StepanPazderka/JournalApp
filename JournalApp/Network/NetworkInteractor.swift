//
//  NetworkInteractor.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 14.12.2023.
//

import Foundation
import OpenAI

protocol NetworkInteractor {    
    static var shared: Self { get }
    
    func getAIoutput(instruction: String, model: Model) async -> Result<String, Error>
}
