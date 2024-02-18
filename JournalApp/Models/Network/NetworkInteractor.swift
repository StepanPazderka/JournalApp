//
//  NetworkInteractor.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 14.12.2023.
//

import Foundation
import OpenAI

protocol NetworkInteractor {
    associatedtype implementingClass
    
    static var shared: implementingClass { get }
    
    func getAIoutput(instruction: String, model: Model, completion: @escaping (Result<String, Error>) -> Void)
}
