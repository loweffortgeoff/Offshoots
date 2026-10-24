import Foundation
import FoundationModels
import Testing
@testable import Offshoots

/// Opt-in network diagnostic. Never enabled by the production app or regular tests.
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.environment["REFLECTION_PCC"] == "1"), .serialized)
struct ReflectionPCCOutputTests {
    #if DEBUG
    @Test func acceptanceCases() async throws {
        guard #available(iOS 27.0, *) else {
            Issue.record("PCC requires iOS 27 or later")
            return
        }
        let path = try #require(ProcessInfo.processInfo.environment["REFLECTION_PCC_OUT"],
            "Set TEST_RUNNER_REFLECTION_PCC_OUT to a fresh JSONL capture path")
        let output = URL(fileURLWithPath: path)
        try #require(!FileManager.default.fileExists(atPath: path), "Do not overwrite an existing evaluation")
        try Data().write(to: output, options: .withoutOverwriting)
        let handle = try FileHandle(forWritingTo: output)
        defer { try? handle.close() }
        final class BundleToken {}
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "reflection-acceptance", withExtension: "json"))
        let cases = try ReflectionEvaluationCase.load(from: Data(contentsOf: url))
        for value in cases {
            let inputs = value.surface == "decision" ? Array(value.decisions.prefix(1)) : value.decisions
            let selected = ReflectionSourceSnapshot.capture(decisions: inputs,
                subjectID: value.surface == "decision" ? inputs.first?.id : nil)
            let provider = PCCEvaluationResponder()
            var record = PCCEvaluationRecord(id: value.id, eligible: value.eligible, surface: value.surface,
                sourceSnapshot: selected, os: ProcessInfo.processInfo.operatingSystemVersionString,
                device: ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "physical; record hardware manually",
                locale: Locale.current.identifier,
                model: "PrivateCloudComputeLanguageModel; moderate; greedy; schema in prompt; exact model revision unavailable",
                availability: String(describing: provider.model.availability),
                quotaBefore: String(describing: provider.model.quotaUsage))
            let start = Date()
            if provider.model.quotaUsage.isLimitReached || !provider.model.isAvailable {
                record.status = "unmeasured"
                record.error = "PCC unavailable or daily quota reached; no fallback attempted"
            } else {
                let service = LiveReflectionService(rawOutput: { record.raw = $0 }, evaluationResponder: provider)
                do {
                    switch value.surface {
                    case "patterns":
                        record.displayed = String(describing: try await service.patterns(
                            digest: ReflectionDigestBuilder.patterns(from: value.decisions)))
                    case "decision":
                        let decision = try #require(value.decisions.first)
                        let digest = try #require(ReflectionDigestBuilder.decision(decision, among: value.decisions))
                        record.displayed = String(describing: try await service.reflect(on: digest))
                    default:
                        record.displayed = String(describing: try await service.cleanUp(note: value.decisions.first?.notes ?? ""))
                    }
                    record.status = "complete"
                } catch is CancellationError {
                    record.status = "cancelled"
                    record.error = "CancellationError"
                } catch {
                    record.status = "error"
                    record.error = String(reflecting: error)
                }
            }
            record.seconds = Date().timeIntervalSince(start)
            record.instructions = provider.instructions
            record.prompt = provider.prompt
            record.maximumResponseTokens = provider.maximumTokens
            record.rawJSON = provider.rawJSON
            record.providerError = provider.providerError
            record.quotaAfter = String(describing: provider.model.quotaUsage)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            try handle.write(contentsOf: encoder.encode(record) + Data([0x0A]))
            try handle.synchronize()
            print("PCC CASE \(record.id): \(record.status) in \(record.seconds)s; \(record.error ?? record.displayed ?? "")")
        }
    }
    #endif

    @Test func accessProbe() async throws {
        guard #available(iOS 27.0, *) else {
            Issue.record("PCC requires iOS 27 or later")
            return
        }
        let model = PrivateCloudComputeLanguageModel()
        print("PCC availability: \(model.availability); quota: \(model.quotaUsage)")
        try #require(model.isAvailable, "PCC unavailable on this test destination")
        let session = LanguageModelSession(model: model, instructions: "Reply with the single word Ready.")
        do {
            let response = try await session.respond(to: "Confirm readiness.",
                options: GenerationOptions(samplingMode: .greedy, maximumResponseTokens: 400),
                contextOptions: ContextOptions(reasoningLevel: .moderate))
            print("PCC access probe: \(response.content)")
            #expect(!response.content.isEmpty)
        } catch {
            print("PCC ACCESS ERROR: \(String(reflecting: error)); NSError: \(error as NSError)")
            throw error
        }
    }
}
