//
//  LiveReflectionService.swift
//  Offshoots
//

import Foundation
import FoundationModels

/// The only file that imports FoundationModels. Each call makes a new session with fixed
/// instructions, greedy sampling and a token cap. Nothing is kept between calls.
@available(iOS 26.0, *)
struct LiveReflectionService: ReflectionGenerating {
    /// Explicit evaluation hook. Production never supplies it.
    var rawOutput: ((String) -> Void)? = nil


    @Generable
    struct GeneratedObservation {
        @Guide(description: "A specific supported observation. No advice, causal claims, or general personality labels.")
        var text: String
        @Guide(description: "Exact bracketed source keys read from this request supporting the observation.")
        var sources: [String]
    }
    @Generable
    struct GeneratedReading {
        @Guide(description: "Zero to three observations. Empty when nothing useful is supported.")
        var observations: [GeneratedObservation]
    }

    private func observations(_ generated: GeneratedReading, snapshot: ReflectionSourceSnapshot, minimum: Int) -> [ReflectionObservation] {
        generated.observations.prefix(3).compactMap {
            try? ReflectionObservation(text: $0.text, evidenceKeys: $0.sources).validated(against: snapshot, minimumDecisions: minimum)
        }
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
    struct GeneratedDecisionReflection {
        @Guide(description: "One or two sentences on how the decision aged")
        var summary: String
        @Guide(description: "Up to three plain observations about what repeats. Empty if nothing repeats")
        var repeating: [String]
        @Guide(description: "One question to carry into the next revisit. Not advice")
        var nextPrompt: String
        @Guide(description: "One sentence on what this decision has in common with the other decisions that went the same way, from their notes. Empty if none went the same way")
        var echo: String
    }

    /// No `repeating` field: a decision with no written notes has nothing to repeat
    @Generable
    struct GeneratedDecisionSummary {
        @Guide(description: "One or two sentences on how the decision aged")
        var summary: String
        @Guide(description: "One question to carry into the next revisit. Not advice")
        var nextPrompt: String
        @Guide(description: "One sentence on what this decision has in common with the other decisions that went the same way, from their notes. Empty if none went the same way")
        var echo: String
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

    func patterns(digest: PatternsDigest) async throws -> PatternsOutput {
        guard let snapshot = digest.snapshot,
              ReflectionEligibility.hasNotesForPatterns(snapshot.decisions) else { throw ReflectionError.emptyOutput }
        let generated = try await generate(GeneratedReading.self,
            instructions: ReflectionPromptBuilder.patternsInstructions,
            prompt: ReflectionPromptBuilder.patternsPrompt(digest), maximumTokens: 600)
        return PatternsOutput(observations: observations(generated, snapshot: snapshot, minimum: 2))
    }

    func reflect(on digest: DecisionDigest) async throws -> DecisionReflectionOutput {
        guard let snapshot = digest.snapshot,
              let subject = snapshot.decisions.first(where: { $0.id == snapshot.subjectID }) else { throw ReflectionError.emptyOutput }
        let generated = try await generate(GeneratedReading.self,
            instructions: ReflectionPromptBuilder.decisionInstructionsWithoutNotes + """
             Add only optional observations with exact source keys. The subject's first result and revisits are different stages.
            Do not invent repeating themes or require a next question. Return empty observations when there is no further insight.
            """,
            prompt: ReflectionPromptBuilder.decisionPrompt(digest), maximumTokens: 600)
        return DecisionReflectionOutput(summary: DecisionReflectionOutput.timeline(subject),
            observations: observations(generated, snapshot: snapshot, minimum: 1))
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
