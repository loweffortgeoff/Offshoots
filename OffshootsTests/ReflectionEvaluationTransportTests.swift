#if DEBUG
import FoundationModels
import Testing
@testable import Offshoots

@available(iOS 26.0, *)
private struct FailingEvaluationResponder: ReflectionModelResponding {
    func respond<Content: Generable>(to prompt: String, generating type: Content.Type,
                                    instructions: String, maximumTokens: Int) async throws -> Content {
        throw ReflectionError.insufficientEvidence
    }
}

@MainActor
struct ReflectionEvaluationTransportTests {
    /// A transport failure must reach the harness, never silently use the on-device model.
    @Test func providerFailureDoesNotFallBack() async throws {
        guard #available(iOS 26.0, *) else { return }
        let digest = ReflectionDigestBuilder.patterns(from: Array(try Fixture.load("reflection-notes").prefix(2)))
        let service = LiveReflectionService(evaluationResponder: FailingEvaluationResponder())
        await #expect(throws: ReflectionError.insufficientEvidence) {
            try await service.patterns(digest: digest)
        }
    }
}
#endif
