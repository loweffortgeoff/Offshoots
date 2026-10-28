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

    /// `pairingComparison()` from the live harness with PCC answering. The snapshot is the
    /// token-budget one, so each case reads every marked decision that fits 4,096 tokens.
    /// On-device runs in the same pass for a side-by-side grade. Writes to `REFLECTION_PCC_OUT`.
    @Test func pairingComparison() async throws {
        guard #available(iOS 27.0, *) else {
            Issue.record("PCC requires iOS 27 or later")
            return
        }
        let path = try #require(ProcessInfo.processInfo.environment["REFLECTION_PCC_OUT"],
            "Set TEST_RUNNER_REFLECTION_PCC_OUT to a fresh capture path")
        try #require(!FileManager.default.fileExists(atPath: path), "Do not overwrite an existing evaluation")
        try Data().write(to: URL(fileURLWithPath: path), options: .withoutOverwriting)
        let handle = try FileHandle(forWritingTo: URL(fileURLWithPath: path))
        defer { try? handle.close() }
        func log(_ text: String) {
            handle.write(Data((text + "\n\n").utf8))
            try? handle.synchronize()
        }
        final class BundleToken {}
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "reflection-acceptance", withExtension: "json"))
        let cases = try ReflectionEvaluationCase.load(from: Data(contentsOf: url)).filter { $0.surface == "patterns" }
        // The 17-decision journal that showed the 6-of-17 problem, graded on whether it answers at all
        let notes = try Fixture.load("reflection-notes")
        let probe = PrivateCloudComputeLanguageModel()
        log("PCC availability \(probe.availability); quota \(probe.quotaUsage); OS \(ProcessInfo.processInfo.operatingSystemVersionString)")
        let modes = ["device-free", "device-pairs", "pcc-free", "pcc-pairs"]
        var passed = Dictionary(uniqueKeysWithValues: modes.map { ($0, 0) })
        var unmeasured = Dictionary(uniqueKeysWithValues: modes.map { ($0, 0) })
        for (index, value) in cases.enumerated() {
            let snapshot = await LiveReflectionService().snapshot(for: .patterns, decisions: value.decisions)
            log("CASE \(index + 1)/\(cases.count) \(value.id) eligible \(value.eligible): \(snapshot.scope)")
            for mode in modes {
                let responder = PCCEvaluationResponder()
                if mode.hasPrefix("pcc"), responder.model.quotaUsage.isLimitReached || !responder.model.isAvailable {
                    unmeasured[mode, default: 0] += 1
                    log("GRADE \(mode) \(value.id) UNMEASURED: \(responder.model.availability); quota \(responder.model.quotaUsage)")
                    continue
                }
                var service = LiveReflectionService(rawOutput: { log("RAW \(mode) \(value.id): " + $0) })
                service.choosesPairs = mode.hasSuffix("pairs")
                if mode.hasPrefix("pcc") { service.evaluationResponder = responder }
                var digest = ReflectionDigestBuilder.patterns(from: value.decisions)
                digest.snapshot = snapshot
                let start = Date()
                let cited: Set<UUID>
                var text = ""
                do {
                    let observation = try await service.patterns(digest: digest).observations.first
                    text = observation?.text ?? ""
                    cited = Set((observation?.evidenceKeys ?? []).compactMap { key in snapshot.evidence.first { $0.key == key }?.decisionID })
                } catch {
                    cited = []
                    text = "(abstained: \(error))\(responder.providerError.map { " provider: \($0)" } ?? "")"
                }
                let pass = value.eligible ? !cited.isEmpty && cited.isSubset(of: Set(value.expectedDecisionIDs)) : cited.isEmpty
                if pass { passed[mode, default: 0] += 1 }
                let seconds = String(format: "%.1f", Date().timeIntervalSince(start))
                log("GRADE \(mode) \(value.id) \(pass ? "PASS" : "FAIL") in \(seconds)s: \(text)")
            }
        }
        log("GRADE TOTAL of \(cases.count): " + modes.map { "\($0) \(passed[$0] ?? 0) (unmeasured \(unmeasured[$0] ?? 0))" }.joined(separator: ", "))

        let snapshot = await LiveReflectionService().snapshot(for: .patterns, decisions: notes)
        log("JOURNAL reflection-notes: \(snapshot.scope)")
        for mode in ["device-free", "pcc-free", "pcc-pairs"] {
            var service = LiveReflectionService(rawOutput: { log("RAW \(mode) reflection-notes: " + $0) })
            service.choosesPairs = mode.hasSuffix("pairs")
            if mode.hasPrefix("pcc") { service.evaluationResponder = PCCEvaluationResponder() }
            var digest = ReflectionDigestBuilder.patterns(from: notes)
            digest.snapshot = snapshot
            do {
                let observation = try await service.patterns(digest: digest).observations.first
                let titles = (observation?.evidenceKeys ?? []).compactMap { key in
                    snapshot.evidence.first { $0.key == key }.flatMap { e in notes.first { $0.id == e.decisionID }?.title } }
                log("JOURNAL \(mode): \(observation?.text ?? "") \(titles)")
            } catch {
                log("JOURNAL \(mode): (abstained: \(error))")
            }
        }
        log("PCC quota after \(probe.quotaUsage)")
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
