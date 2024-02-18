//
//  NetworkInteractorImpl.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 14.12.2023.
//

import Foundation
import OpenAI

final class NetworkInteractorImpl: NetworkInteractor {
    private var client: OpenAI?
    
    static public let shared = NetworkInteractorImpl()
    
    init() {
        let apiKey = "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"
        client = OpenAI(configuration: OpenAI.Configuration(token: apiKey))
    }
    
    func getAIoutput(instruction: String, model: Model, completion: @escaping (Result<String, Error>) -> Void) {
        let chat = Chat(role: .assistant, content: instruction, name: "Lumi")
        let chatQuery = ChatQuery(model: .gpt3_5Turbo_16k_0613, messages: [chat])
        
        client?.chats(query: chatQuery, completion: { result in
            switch result {
            case .success(let results):
                let output = results.choices.first?.message.content ?? ""
                completion(.success(output.cleaned().replacingSmileysWithEmojis().cleanString()))
            case .failure(let error):
                print(error.localizedDescription)
                completion(.failure(error))
            }
        })
    }
}
