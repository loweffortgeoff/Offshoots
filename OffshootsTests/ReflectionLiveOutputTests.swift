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

    /// `reflection-hindsight` is `reflection-notes` with Hindsight answers added
    @Test(arguments: ["reflection-notes", "reflection-hindsight"])
    func patterns(fixture: String) async throws {
        guard #available(iOS 26.4, *) else { return }
        try requireModel()
        let decisions = try Fixture.load(fixture)
        let service = LiveReflectionService(rawOutput: { log("RAW: " + $0) })
        var digest = ReflectionDigestBuilder.patterns(from: decisions)
        let start = Date()
        digest.snapshot = await service.snapshot(for: .patterns, decisions: decisions)
        log("SNAPSHOT \(fixture): \(digest.snapshot?.scope ?? "") in \(Date().timeIntervalSince(start)) seconds")
        let prompt = ReflectionPromptBuilder.patternsPrompt(digest)
        try await report(
            "Patterns: \(fixture)",
            instructions: ReflectionPromptBuilder.patternsInstructions,
            prompt: prompt,
            schema: LiveReflectionService.GeneratedConnection.generationSchema
        )
        let generation = Date()
        let output = try await service.patterns(digest: digest)
        log("GENERATED \(fixture) in \(Date().timeIntervalSince(generation)) seconds")
        log("Patterns output (\(fixture)):\n" + output.observations.map { "- \($0.text) \($0.evidenceKeys)" }.joined(separator: "\n"))
    }

    /// Times the token-budget selection on a large journal: the fixture repeated with new IDs
    @Test func largeJournalSnapshotTime() async throws {
        guard #available(iOS 26.4, *) else { return }
        try requireModel()
        let base = try Fixture.load("reflection-hindsight")
        let decisions = (0..<9).flatMap { round in
            base.map { d -> Decision in
                var copy = Decision(title: d.title, category: d.category, stakes: d.stakes, expected: d.expected, actual: d.actual,
                                    notes: d.notes, reflection: d.reflection, createdAt: d.createdAt.addingTimeInterval(Double(-round) * 86_400 * 60),
                                    resolvedAt: d.resolvedAt.map { $0.addingTimeInterval(Double(-round) * 86_400 * 60) }, followUpDate: d.followUpDate,
                                    revisits: d.revisits.map { Revisit(date: $0.date, outcome: $0.outcome, note: $0.note, hindsight: $0.hindsight) },
                                    hindsight: d.hindsight)
                copy.title = d.title + " \(round)"
                return copy
            }
        }
        let start = Date()
        let snapshot = await LiveReflectionService().snapshot(for: .patterns, decisions: decisions)
        log("LARGE SNAPSHOT \(decisions.count) decisions: \(snapshot.scope) in \(Date().timeIntervalSince(start)) seconds")
    }

    @Test(arguments: decisionTitles)
    func decisionReflection(title: String) async throws {
        guard #available(iOS 26.4, *) else { return }
        try requireModel()
        let decision = try #require(try Fixture.load("reflection-notes").first { $0.title == title })
        var digest = try #require(ReflectionDigestBuilder.decision(decision, among: try Fixture.load("reflection-notes")))
        digest.snapshot = await LiveReflectionService().snapshot(for: .decision(decision.id), decisions: try Fixture.load("reflection-notes"))
        try await report(
            "Decision: \(title)",
            instructions: ReflectionPromptBuilder.decisionChangeInstructions,
            prompt: ReflectionPromptBuilder.decisionPrompt(digest),
            schema: LiveReflectionService.GeneratedDecisionChange.generationSchema
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

    @Test func purchaseSample() async throws {
        guard #available(iOS 26.4, *) else { return }
        try requireModel()
        let decisions = Array(try Fixture.load("reflection-notes").prefix(2))
        let output = try await LiveReflectionService(rawOutput: { log("SAMPLE RAW: " + $0) })
            .patterns(digest: ReflectionDigestBuilder.patterns(from: decisions))
        log("SAMPLE DISPLAY: \(output)")
        #expect(!output.observations.isEmpty, "A purchase sample must demonstrate a supported generated connection")
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
            let kind: SavedReflection.Kind = value.surface == "decision" ? .decision(value.decisions.first?.id ?? UUID()) : .patterns
            let selected = await service.snapshot(for: kind, decisions: value.decisions)
            log("SELECTED \(value.id): \(selected.scope) keys \(selected.evidence.map { "\($0.key)=\($0.decisionID)" })")
            do {
                switch value.surface {
                case "patterns":
                    var digest = ReflectionDigestBuilder.patterns(from: value.decisions)
                    digest.snapshot = selected
                    log("DISPLAY \(try await service.patterns(digest: digest))")
                case "decision":
                    if let decision = value.decisions.first, var digest = ReflectionDigestBuilder.decision(decision, among: value.decisions) {
                        digest.snapshot = selected
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

    /// Grades free choice against code-chosen pairs on every Patterns acceptance case. A case
    /// passes when an eligible case cites only expected decisions, or an ineligible one abstains.
    @Test func pairingComparison() async throws {
        guard #available(iOS 26.4, *) else { return }
        try requireModel()
        final class BundleToken {}
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "reflection-acceptance", withExtension: "json"))
        let cases = try ReflectionEvaluationCase.load(from: Data(contentsOf: url)).filter { $0.surface == "patterns" }
        var passed = ["free": 0, "pairs": 0]
        for value in cases {
            let snapshot = await LiveReflectionService().snapshot(for: .patterns, decisions: value.decisions)
            let pairs = ReflectionPairing.pairs(in: snapshot)
            log("PAIRS \(value.id) [\(NoteSimilarity.lastMeasure)]: " + pairs.prefix(3).map { "\($0.firstKey)+\($0.secondKey) sim \(String(format: "%.2f", $0.similarity)) score \(String(format: "%.2f", $0.score)) \($0.reasons)" }.joined(separator: " | "))
            for mode in ["free", "pairs"] {
                var service = LiveReflectionService(rawOutput: { log("RAW \(mode) \(value.id): " + $0) })
                service.choosesPairs = mode == "pairs"
                var digest = ReflectionDigestBuilder.patterns(from: value.decisions)
                digest.snapshot = snapshot
                let cited: Set<UUID>
                var text = ""
                do {
                    let observation = try await service.patterns(digest: digest).observations.first
                    text = observation?.text ?? ""
                    cited = Set((observation?.evidenceKeys ?? []).compactMap { key in snapshot.evidence.first { $0.key == key }?.decisionID })
                } catch {
                    cited = []
                    text = "(abstained: \(error))"
                }
                let pass = value.eligible ? !cited.isEmpty && cited.isSubset(of: Set(value.expectedDecisionIDs)) : cited.isEmpty
                if pass { passed[mode, default: 0] += 1 }
                log("GRADE \(mode) \(value.id) \(pass ? "PASS" : "FAIL") eligible \(value.eligible): \(text)")
            }
        }
        log("GRADE TOTAL of \(cases.count): free \(passed["free"] ?? 0), pairs \(passed["pairs"] ?? 0)")
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
