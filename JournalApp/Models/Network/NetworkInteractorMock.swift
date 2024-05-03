//
//  NetworkInteractorMock.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 04.03.2024.
//

import Foundation
import OpenAI

class NetworkInteractorMock: NetworkInteractor {
    static var shared = NetworkInteractorMock()
    
    func getAIoutput(instruction: String, model: Model) async -> Result<String, Error> {
        let chat = Chat(role: .assistant, content: instruction, name: "Lumi")
        let chatQuery = ChatQuery(model: model, messages: [chat])

        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            let output = "Just some generic text output"
            return .success(output.cleaned().replacingSmileysWithEmojis().cleanString())
        } catch {
            print(error.localizedDescription)
            return .failure(error)
        }
    }
}
