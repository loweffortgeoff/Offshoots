//
//  ReflectionLiveOutputTests.swift
//  OffshootsTests
//

import Foundation
import FoundationModels
import Testing
@testable import Offshoots

/// Not a unit test. Runs the real on-device model on `reflection-notes.json` and prints the
/// prompt sizes and the output, so prompt changes can be compared before and after.
/// Off by default. Run with `TEST_RUNNER_REFLECTION_LIVE=1` and
/// `TEST_RUNNER_REFLECTION_LIVE_OUT=<file>` (see the Reflection Depth plan).
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.environment["REFLECTION_LIVE"] == "1"), .serialized)
struct ReflectionLiveOutputTests {

    /// One decision that went worse, with a revisit, and one plain miss
    nonisolated static let decisionTitles = ["Say yes to leading the launch project", "Upgrade to the new laptop"]

    @Test func patterns() async throws {
        guard #available(iOS 26.4, *) else { return }
        try requireModel()
        let digest = ReflectionDigestBuilder.patterns(from: try Fixture.load("reflection-notes"))
        let prompt = ReflectionPromptBuilder.patternsPrompt(digest)
        try await report(
            "Patterns",
            instructions: ReflectionPromptBuilder.patternsInstructions,
            prompt: prompt,
            schema: LiveReflectionService.GeneratedPatterns.generationSchema
        )
        let output = try await LiveReflectionService(rawOutput: { log("RAW: " + $0) }).patterns(digest: digest)
        log("Patterns output:\n" + output.lines.map { "- \($0.label): \($0.text)" }.joined(separator: "\n"))
    }

    @Test(arguments: decisionTitles)
    func decisionReflection(title: String) async throws {
        guard #available(iOS 26.4, *) else { return }
        try requireModel()
        let decision = try #require(try Fixture.load("reflection-notes").first { $0.title == title })
        let digest = try #require(ReflectionDigestBuilder.decision(decision, among: try Fixture.load("reflection-notes")))
        try await report(
            "Decision: \(title)",
            instructions: ReflectionPromptBuilder.decisionInstructions + ReflectionPromptBuilder.historyRule,
            prompt: ReflectionPromptBuilder.decisionPrompt(digest),
            schema: LiveReflectionService.GeneratedDecisionReflection.generationSchema
        )
        let output = try await LiveReflectionService(rawOutput: { log("RAW: " + $0) }).reflect(on: digest)
        log("""
        Decision output (\(title)):
        Summary: \(output.summary)
        Echo: \(output.echo)
        Repeating:
        \(output.repeating.map { "- \($0)" }.joined(separator: "\n"))
        Next: \(output.nextPrompt)
        """)
    }

    @Test(arguments: [DecisionCategory.money, .work])
    func lookBack(category: DecisionCategory) async throws {
        guard #available(iOS 26.4, *) else { return }
        try requireModel()
        let digest = try #require(ReflectionDigestBuilder.lookBack(category: category, in: try Fixture.load("reflection-notes")))
        try await report(
            "Look Back: \(digest.category)",
            instructions: ReflectionPromptBuilder.lookBackInstructions,
            prompt: ReflectionPromptBuilder.lookBackPrompt(digest),
            schema: LiveReflectionService.GeneratedPatterns.generationSchema
        )
        let output = try await LiveReflectionService(rawOutput: { log("RAW: " + $0) }).lookBack(digest: digest)
        log("Look Back output (\(digest.category)):\n\(output.stats.headline ?? "(no headline)")\n\(output.stats.summary)\n" + output.lines.map { "- \($0.label): \($0.text)" }.joined(separator: "\n"))
    }

    @Test func acceptanceCases() async throws {
        guard #available(iOS 26.4, *) else { return }
        try requireModel()
        final class BundleToken {}
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "reflection-acceptance", withExtension: "json"))
        let cases = try ReflectionEvaluationCase.load(from: Data(contentsOf: url))
        for value in cases {
            let start = Date()
            log("CASE \(value.id) | eligible \(value.eligible) | OS \(ProcessInfo.processInfo.operatingSystemVersionString) | device \(ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "physical-device; record hardware manually") | scope \(value.decisions.map(\.id))")
            let service = LiveReflectionService(rawOutput: { log("RAW \(value.id): " + $0) })
            do {
                switch value.surface {
                case "patterns":
                    log("DISPLAY \(try await service.patterns(digest: ReflectionDigestBuilder.patterns(from: value.decisions)))")
                case "decision":
                    if let decision = value.decisions.first, let digest = ReflectionDigestBuilder.decision(decision, among: value.decisions) {
                        log("DISPLAY \(try await service.reflect(on: digest))")
                    }
                default:
                    log("DISPLAY \(try await service.cleanUp(note: value.decisions.first?.notes ?? ""))")
                }
                log("COMPLETE \(value.id) seconds \(Date().timeIntervalSince(start))")
            } catch {
                log("ERROR \(value.id) seconds \(Date().timeIntervalSince(start)): \(error)")
            }
        }
    }

    // MARK: - Helpers

    @available(iOS 26.4, *)
    private func requireModel() throws {
        let availability = SystemLanguageModel.default.availability
        log("Model availability: \(availability)")
        try #require(availability == .available, "The on-device model is not available on this run destination")
    }

    /// Instructions are counted as a prompt string. The count is close, not exact.
    @available(iOS 26.4, *)
    private func report(_ label: String, instructions: String, prompt: String, schema: GenerationSchema) async throws {
        let model = SystemLanguageModel.default
        let instructionTokens = try await model.tokenCount(for: instructions)
        let promptTokens = try await model.tokenCount(for: prompt)
        let schemaTokens = try await model.tokenCount(for: schema)
        log("""
        \(label)
        Context size: \(model.contextSize) tokens
        Instructions: \(instructionTokens), prompt: \(promptTokens), schema: \(schemaTokens), \
        total before the response: \(instructionTokens + promptTokens + schemaTokens)
        Prompt text:
        \(prompt)
        """)
    }

    /// Printed output does not reach the xcodebuild log from a cloned simulator, so it also
    /// goes to the file named by `REFLECTION_LIVE_OUT` (a path on the Mac), if set.
    private func log(_ text: String) {
        print(text)
        guard let path = ProcessInfo.processInfo.environment["REFLECTION_LIVE_OUT"] else { return }
        let url = URL(fileURLWithPath: path)
        let data = Data((text + "\n\n").utf8)
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: url)
        }
    }
}
