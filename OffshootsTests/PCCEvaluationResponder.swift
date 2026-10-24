#if DEBUG
import Foundation
import FoundationModels
@testable import Offshoots

/// Network transport lives only in the test bundle. The app shares prompts and validation.
@available(iOS 27.0, *)
final class PCCEvaluationResponder: ReflectionModelResponding {
    let model = PrivateCloudComputeLanguageModel()
    var instructions: String?
    var prompt: String?
    var maximumTokens: Int?
    var rawJSON: String?
    var providerError: String?

    func respond<Content: Generable>(to prompt: String, generating type: Content.Type,
                                    instructions: String, maximumTokens: Int) async throws -> Content {
        self.instructions = instructions
        self.prompt = prompt
        self.maximumTokens = maximumTokens
        do {
            guard model.isAvailable else {
                throw NSError(domain: "ReflectionPCCEvaluation", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "PCC unavailable: \(model.availability)"])
            }
            let session = LanguageModelSession(model: model, instructions: instructions)
            let response = try await session.respond(to: prompt, generating: type,
                options: GenerationOptions(samplingMode: .greedy, maximumResponseTokens: maximumTokens),
                contextOptions: ContextOptions(includeSchemaInPrompt: true, reasoningLevel: .moderate))
            rawJSON = response.content.generatedContent.jsonString
            return response.content
        } catch {
            let native = error as NSError
            providerError = "\(String(reflecting: error)); domain=\(native.domain); code=\(native.code); \(native.localizedDescription)"
            throw error
        }
    }
}

struct PCCEvaluationRecord: Codable {
    let id: String
    let eligible: Bool
    let surface: String
    let sourceSnapshot: ReflectionSourceSnapshot
    let os: String
    let device: String
    let locale: String
    let model: String
    let availability: String
    let quotaBefore: String
    var quotaAfter: String?
    var instructions: String?
    var prompt: String?
    var maximumResponseTokens: Int?
    var raw: String?
    var rawJSON: String?
    var displayed: String?
    var providerError: String?
    var error: String?
    var seconds: Double = 0
    var status: String = "notStarted"
}
#endif
