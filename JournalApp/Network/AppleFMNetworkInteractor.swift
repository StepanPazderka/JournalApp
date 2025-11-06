import Foundation
import FoundationModels

final class AppleFMNetworkInteractor: NetworkInteractor {
    static let shared = AppleFMNetworkInteractor()
    
    private init() {}

    enum FMError: Error { case emptyOutput }

    func getAIoutput(instruction: String) async -> Result<String, Error> {
        do {
            let prompt = instruction.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !prompt.isEmpty else { return .failure(FMError.emptyOutput) }

            // Caller-provided instruction drives everything; no extra system text here.
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? .failure(FMError.emptyOutput) : .success(text)
        } catch {
            return .failure(error)
        }
    }
}
