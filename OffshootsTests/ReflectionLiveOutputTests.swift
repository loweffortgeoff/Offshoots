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

    /// The fixture's last date is 2026-10-03
    static let now = ISO8601DateFormatter().date(from: "2026-10-05T12:00:00Z")!

    /// One decision that went worse, with a revisit, and one plain miss
    nonisolated static let decisionTitles = ["Say yes to leading the launch project", "Upgrade to the new laptop"]

    @Test func patterns() async throws {
        guard #available(iOS 26.4, *) else { return }
        try requireModel()
        let digest = ReflectionDigestBuilder.patterns(from: try Fixture.load("reflection-notes"), now: Self.now)
        let prompt = ReflectionPromptBuilder.patternsPrompt(digest)
        try await report(
            "Patterns",
            instructions: ReflectionPromptBuilder.patternsInstructions,
            prompt: prompt,
            schema: LiveReflectionService.GeneratedPatterns.generationSchema
        )
        let output = try await LiveReflectionService().patterns(digest: digest)
        log("Patterns output:\n" + output.observations.map { "- \($0)" }.joined(separator: "\n"))
    }

    @Test(arguments: decisionTitles)
    func decisionReflection(title: String) async throws {
        guard #available(iOS 26.4, *) else { return }
        try requireModel()
        let decision = try #require(try Fixture.load("reflection-notes").first { $0.title == title })
        let digest = try #require(ReflectionDigestBuilder.decision(decision))
        try await report(
            "Decision: \(title)",
            instructions: ReflectionPromptBuilder.decisionInstructions,
            prompt: ReflectionPromptBuilder.decisionPrompt(digest),
            schema: LiveReflectionService.GeneratedDecisionReflection.generationSchema
        )
        let output = try await LiveReflectionService().reflect(on: digest)
        log("""
        Decision output (\(title)):
        Summary: \(output.summary)
        Repeating:
        \(output.repeating.map { "- \($0)" }.joined(separator: "\n"))
        Next: \(output.nextPrompt)
        """)
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
