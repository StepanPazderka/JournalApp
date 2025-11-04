//
//  NetworkInteractorImpl.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 14.12.2023.
//

import Foundation
// Legacy OpenAI implementation removed.

final class NetworkInteractorImpl: NetworkInteractor {
    
    static public let shared = NetworkInteractorImpl()
    
    func getAIoutput(instruction: String, modelIdentifier: String) async -> Result<String, Error> {
        // Legacy implementation redirected to Foundation Models interactor.
        return await AppleFMNetworkInteractor.shared.getAIoutput(instruction: instruction, modelIdentifier: modelIdentifier)
    }
}
