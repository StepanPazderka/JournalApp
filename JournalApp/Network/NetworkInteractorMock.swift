//
//  NetworkInteractorMock.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 04.03.2024.
//

import Foundation

final class NetworkInteractorMock: NetworkInteractor {
    static var shared = NetworkInteractorMock()
    
    func getAIoutput(instruction: String, modelIdentifier: String) async -> Result<String, Error> {
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            let output = "[Mock FM] " + instruction
            return .success(output)
        } catch {
            return .failure(error)
        }
    }
}
