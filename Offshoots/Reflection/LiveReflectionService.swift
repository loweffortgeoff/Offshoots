//
//  LiveReflectionService.swift
//  Offshoots
//

import Foundation
import FoundationModels

/// Each call makes a new session with fixed
/// instructions, greedy sampling and a token cap. Nothing is kept between calls.
@available(iOS 26.0, *)
struct LiveReflectionService: ReflectionGenerating {
    /// Explicit evaluation hook. Production never supplies it.
    var rawOutput: ((String) -> Void)? = nil
    /// False lets the model choose the Patterns pair from the whole snapshot (the harness compares both)
    var choosesPairs = true
    static let pairAttempts = 2
    static let pairResponseTokens = 200

    #if DEBUG
    var evaluationResponder: (any ReflectionModelResponding)? = nil
    #endif


    @Generable
    struct GeneratedConnection {
        @Guide(description: "One short comparison of what written notes on two DIFFERENT decisions share. Synthesize a connection, not a list or copied note. Empty if no meaningful connection exists.")
        var connection: String
        @Guide(description: "The exact short evidence key for a written note from the FIRST supporting decision, such as R1.log. Empty if connection is empty.")
        var firstSource: String
        @Guide(description: "The exact short evidence key for a written note from a DIFFERENT supporting decision, such as R2.log. Never reuse the first decision. Empty if connection is empty.")
        var secondSource: String
    }

    @Generable
    struct GeneratedPairLink {
        @Guide(description: "One sentence on a concrete thing the two written notes share, naming both situations. Empty if the notes share nothing concrete.")
        var connection: String
    }

    @Generable
    struct GeneratedDecisionChange {
        @Guide(description: "One short explanation of a change between earlier and later notes on this decision. Compare stages rather than list or copy notes. Do not infer causes or feelings. Empty if only ratings or unrelated notes exist.")
        var change: String
        @Guide(description: "Exact earlier source key from this request, such as R1.log or R1.outcome. Empty when change is empty.")
        var earlierSource: String
        @Guide(description: "Exact DIFFERENT later source key from this request, such as R1.outcome or R1.revisit1, supporting the change. Empty when change is empty.")
        var laterSource: String
    }

    // MARK: - Generated shapes

    /// One sentence per group, so the model covers each group once and cannot repeat itself.
    /// Asking the model to start with the trait made it copy one note (plan, chunk 6), so
    /// code removes the group opening instead (`ReflectionText.dropGroupOpening`).
    @Generable
    struct GeneratedPatterns {
        @Guide(description: "One sentence on what the notes on decisions that went worse than predicted share. Empty if that group has no notes")
        var worse: String
        @Guide(description: "One sentence on what the notes on decisions that went as predicted share. Empty if that group has no notes")
        var asPredicted: String
        @Guide(description: "One sentence on what the notes on decisions that went better than predicted share. Empty if that group has no notes")
        var better: String
    }

    /// A group with no notes keeps no line, whatever the model wrote for it
    private static func groupLines(_ generated: GeneratedPatterns, worse: Bool, asPredicted: Bool, better: Bool) -> [ReflectionGroupLine] {
        [
            worse ? ReflectionGroupLine(label: ReflectionGroupLine.worseLabel, text: generated.worse) : nil,
            asPredicted ? ReflectionGroupLine(label: ReflectionGroupLine.asPredictedLabel, text: generated.asPredicted) : nil,
            better ? ReflectionGroupLine(label: ReflectionGroupLine.betterLabel, text: generated.better) : nil,
        ].compactMap { $0 }
    }

    @Generable
    struct GeneratedCleanNote {
        @Guide(description: "The note with spelling, capitals, punctuation and grammar fixed. Same meaning and language")
        var text: String
    }

    // MARK: - Availability

    /// Read on launch and each time the app becomes active, because the model can become ready later.
    static func availability() -> ModelAvailability {
        let model = SystemLanguageModel.default
        guard model.supportsLocale() else { return .unsupported }
        switch model.availability {
        case .available:
            return .available
        case .unavailable(.modelNotReady):
            return .notReady(reason: "The on-device model is still getting ready. Reopen the app in a little while.")
        case .unavailable:
            return .unsupported
        }
    }

    // MARK: - ReflectionGenerating

    /// Prompts are sized for the 4,096-token context of iOS 26, even where the model reports more
    /// (8,192 on the iOS 27.0 simulator).
    static let contextBudget = 4096
    /// Room for the scope line, whose numbers change once the selection is final
    static let promptMargin = 64
    static let patternsResponseTokens = 400
    static let decisionResponseTokens = 400
    /// No record line costs less: a title-only record with its key is about this many tokens
    static let smallestRecord = 20

    /// Fills the context with as many whole records as fit, counted in real tokens. Before
    /// iOS 26.4, or when counting fails, it falls back to the byte bound.
    func snapshot(for kind: SavedReflection.Kind, decisions: [Decision]) async -> ReflectionSourceSnapshot {
        let fallback = Self.defaultSnapshot(for: kind, decisions: decisions)
        guard #available(iOS 26.4, *) else { return fallback }
        let subjectID = fallback.subjectID
        let sources = subjectID.map { id in decisions.filter { $0.id == id } } ?? decisions
        let model = SystemLanguageModel.default
        let (instructions, schema, response) = switch kind {
        case .patterns: (ReflectionPromptBuilder.patternsInstructions, GeneratedConnection.generationSchema, Self.patternsResponseTokens)
        case .decision: (ReflectionPromptBuilder.decisionChangeInstructions, GeneratedDecisionChange.generationSchema, Self.decisionResponseTokens)
        }
        do {
            let fixed = try await model.tokenCount(for: instructions) + model.tokenCount(for: schema)
            let budget = min(model.contextSize, Self.contextBudget) - fixed - response - Self.promptMargin
            // Each record is counted once, on its own, and the counts are summed. Counting the
            // whole prompt for every candidate took 4.4 s for 153 decisions on the simulator.
            var used = try await model.tokenCount(for: ReflectionPromptBuilder.snapshotPrompt(
                ReflectionSourceSnapshot(decisions: [], eligibleDecisionIDs: [], subjectID: subjectID, omittedCount: 0)))
            // Each call costs about 25 ms, so once even the cheapest record seen cannot fit, stop counting
            var cheapest = Int.max
            let selected = try await ReflectionSourceSnapshot.capture(decisions: sources, subjectID: subjectID) { candidate in
                guard let added = candidate.decisions.last, budget - used >= min(cheapest, Self.smallestRecord) else { return false }
                let alone = ReflectionSourceSnapshot(decisions: [added], eligibleDecisionIDs: [], subjectID: subjectID, omittedCount: 0).prompt
                // A longer key ("R12" for "R1") on each line
                let cost = try await model.tokenCount(for: alone) + 2 * alone.split(separator: "\n").count
                cheapest = min(cheapest, cost)
                guard used + cost <= budget else { return false }
                used += cost
                return true
            }
            let total = try await model.tokenCount(for: ReflectionPromptBuilder.snapshotPrompt(selected))
            return total <= budget + Self.promptMargin ? selected : fallback
        } catch {
            return fallback
        }
    }

    func patterns(digest: PatternsDigest) async throws -> PatternsOutput {
        guard let snapshot = digest.snapshot,
              ReflectionEligibility.hasNotesForPatterns(snapshot.decisions) else { throw ReflectionError.emptyOutput }
        guard choosesPairs else { return try await freeChoicePatterns(digest: digest, snapshot: snapshot) }
        // Code chooses the pair; the model only words it, or leaves it empty and the next pair is tried
        for pair in ReflectionPairing.pairs(in: snapshot).prefix(Self.pairAttempts) {
            let generated = try await generate(GeneratedPairLink.self,
                instructions: ReflectionPromptBuilder.pairInstructions,
                prompt: ReflectionPromptBuilder.pairPrompt(pair, snapshot: snapshot), maximumTokens: Self.pairResponseTokens)
            guard !generated.connection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            let observation = try ReflectionObservation(text: generated.connection,
                evidenceKeys: [pair.firstKey, pair.secondKey]).validated(against: snapshot, minimumDecisions: 2)
            return PatternsOutput(observations: [observation])
        }
        throw ReflectionError.insufficientEvidence
    }

    /// The model reads every record and picks the pair itself. Kept for the harness comparison.
    private func freeChoicePatterns(digest: PatternsDigest, snapshot: ReflectionSourceSnapshot) async throws -> PatternsOutput {
        let generated = try await generate(GeneratedConnection.self,
            instructions: ReflectionPromptBuilder.patternsInstructions,
            prompt: ReflectionPromptBuilder.patternsPrompt(digest), maximumTokens: Self.patternsResponseTokens)
        guard !generated.connection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ReflectionError.insufficientEvidence }
        let observation = try ReflectionObservation(text: generated.connection,
            evidenceKeys: [generated.firstSource, generated.secondSource]).validated(against: snapshot, minimumDecisions: 2)
        return PatternsOutput(observations: [observation])
    }

    func reflect(on digest: DecisionDigest) async throws -> DecisionReflectionOutput {
        guard let snapshot = digest.snapshot,
              let subject = snapshot.decisions.first(where: { $0.id == snapshot.subjectID }) else { throw ReflectionError.emptyOutput }
        let generated = try await generate(GeneratedDecisionChange.self,
            instructions: ReflectionPromptBuilder.decisionChangeInstructions,
            prompt: ReflectionPromptBuilder.decisionPrompt(digest), maximumTokens: Self.decisionResponseTokens)
        return Self.decisionOutput(generated, subject: subject, snapshot: snapshot)
    }

    static func decisionOutput(_ generated: GeneratedDecisionChange, subject: Decision,
                               snapshot: ReflectionSourceSnapshot) -> DecisionReflectionOutput {
        var changes: [ReflectionObservation] = []
        if !generated.change.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let observation = try? ReflectionObservation(text: generated.change,
                evidenceKeys: [generated.earlierSource, generated.laterSource]).validatedChange(against: snapshot, subjectID: subject.id) {
            changes = [observation]
        }
        return DecisionReflectionOutput(summary: DecisionReflectionOutput.timeline(subject), observations: changes)
    }

    /// Reuses the Patterns shape: one sentence per result group
    func lookBack(digest: LookBackDigest) async throws -> LookBackOutput {
        // Nothing written means nothing to read: the counts alone, with no model call
        guard digest.hasNotes else { return LookBackOutput(stats: digest.stats, lines: []) }
        let generated = try await generate(
            GeneratedPatterns.self,
            instructions: ReflectionPromptBuilder.lookBackInstructions,
            prompt: ReflectionPromptBuilder.lookBackPrompt(digest),
            maximumTokens: 300
        )
        let lines = Self.groupLines(generated, worse: digest.worseHasNotes, asPredicted: digest.asPredictedHasNotes, better: digest.betterHasNotes)
        return LookBackOutput(stats: digest.stats, lines: lines).validated().droppingTitleCopies(digest.history.map(\.title))
    }

    func cleanUp(note: String) async throws -> CleanedNote {
        guard !ReflectionText.looksLikeModelInstruction(note) else { throw ReflectionError.instructionLikeInput }
        let generated = try await generate(
            GeneratedCleanNote.self,
            instructions: ReflectionPromptBuilder.cleanUpInstructions,
            prompt: ReflectionPromptBuilder.cleanUpPrompt(note: note),
            maximumTokens: 500
        )
        return try CleanedNote(text: generated.text).validated()
    }

    // MARK: - Helpers

    private func generate<Content: Generable>(
        _ type: Content.Type,
        instructions: String,
        prompt: String,
        maximumTokens: Int
    ) async throws -> Content {
        do {
            if #available(iOS 26.4, *) {
                let model = SystemLanguageModel.default
                let instructionCount = try await model.tokenCount(for: instructions)
                let promptCount = try await model.tokenCount(for: prompt)
                let schemaCount = try await model.tokenCount(for: type.generationSchema)
                guard instructionCount + promptCount + schemaCount + maximumTokens < model.contextSize else { throw ReflectionError.failed }
            }
            #if DEBUG
            if let evaluationResponder {
                let response = try await evaluationResponder.respond(to: prompt, generating: type,
                    instructions: instructions, maximumTokens: maximumTokens)
                rawOutput?(String(describing: response))
                return response
            }
            #endif
            let session = LanguageModelSession(instructions: instructions)
            let options = GenerationOptions(samplingMode: .greedy, maximumResponseTokens: maximumTokens)
            let response = try await session.respond(to: prompt, generating: type, options: options).content
            rawOutput?(String(describing: response))
            return response
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as ReflectionError {
            throw error
        } catch {
            // Guardrail, context size, locale and model errors all read the same to the user
            throw ReflectionError.failed
        }
    }
}
