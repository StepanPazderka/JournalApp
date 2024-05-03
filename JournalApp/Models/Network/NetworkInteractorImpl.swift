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
		if let apiKey = readFirstLineOfFileInBundle(fileName: "api", fileType: "txt") {
			client = OpenAI(configuration: OpenAI.Configuration(token: apiKey))
		}
    }
    
    func getAIoutput(instruction: String, model: Model) async -> Result<String, Error> {
        let chat = Chat(role: .assistant, content: instruction, name: "Lumi")
        let chatQuery = ChatQuery(model: model, messages: [chat])

        do {
            let results = try await client?.chats(query: chatQuery)
            let output = results?.choices.first?.message.content ?? ""
            return .success(output.cleaned().replacingSmileysWithEmojis().cleanString())
        } catch {
            print(error.localizedDescription)
            return .failure(error)
        }
    }
}
