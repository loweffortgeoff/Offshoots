#if DEBUG
import FoundationModels

/// Evaluation transport only. The production factory never supplies one.
@available(iOS 26.0, *)
protocol ReflectionModelResponding {
    func respond<Content: Generable>(to prompt: String, generating type: Content.Type,
                                    instructions: String, maximumTokens: Int) async throws -> Content
}
#endif
