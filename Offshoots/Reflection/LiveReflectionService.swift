//
//  LiveReflectionService.swift
//  Offshoots
//

import FoundationModels

/// The only file that imports FoundationModels. Each call makes a new session with fixed
/// instructions, greedy sampling and a token cap. Nothing is kept between calls.
@available(iOS 26.0, *)
struct LiveReflectionService: ReflectionGenerating {

    // MARK: - Generated shapes

    @Generable
    struct GeneratedPatterns {
        @Guide(description: "Two to four plain observations about patterns, one sentence each")
        var observations: [String]
    }

    @Generable
    struct GeneratedDecisionReflection {
        @Guide(description: "One or two sentences on how the decision aged")
        var summary: String
        @Guide(description: "Up to three plain observations about what repeats. Empty if nothing repeats")
        var repeating: [String]
        @Guide(description: "One question to carry into the next revisit. Not advice")
        var nextPrompt: String
    }

    /// No `repeating` field: a decision with no written notes has nothing to repeat
    @Generable
    struct GeneratedDecisionSummary {
        @Guide(description: "One or two sentences on how the decision aged")
        var summary: String
        @Guide(description: "One question to carry into the next revisit. Not advice")
        var nextPrompt: String
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
            return .notReady(reason: "The on-device model is still getting ready. Try again soon.")
        case .unavailable:
            return .unsupported
        }
    }

    // MARK: - ReflectionGenerating

    func patterns(digest: PatternsDigest) async throws -> PatternsOutput {
        let generated = try await generate(
            GeneratedPatterns.self,
            instructions: ReflectionPromptBuilder.patternsInstructions,
            prompt: ReflectionPromptBuilder.patternsPrompt(digest),
            maximumTokens: 300
        )
        return try PatternsOutput(observations: generated.observations).validated()
    }

    func reflect(on digest: DecisionDigest) async throws -> DecisionReflectionOutput {
        guard digest.hasWrittenText else {
            let generated = try await generate(
                GeneratedDecisionSummary.self,
                instructions: ReflectionPromptBuilder.decisionInstructionsWithoutNotes,
                prompt: ReflectionPromptBuilder.decisionPrompt(digest),
                maximumTokens: 300
            )
            return try DecisionReflectionOutput(
                summary: generated.summary,
                repeating: [],
                nextPrompt: generated.nextPrompt
            ).validated()
        }
        let generated = try await generate(
            GeneratedDecisionReflection.self,
            instructions: ReflectionPromptBuilder.decisionInstructions,
            prompt: ReflectionPromptBuilder.decisionPrompt(digest),
            maximumTokens: 400
        )
        return try DecisionReflectionOutput(
            summary: generated.summary,
            repeating: generated.repeating,
            nextPrompt: generated.nextPrompt
        ).validated()
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
            let session = LanguageModelSession(instructions: instructions)
            let options = GenerationOptions(samplingMode: .greedy, maximumResponseTokens: maximumTokens)
            return try await session.respond(to: prompt, generating: type, options: options).content
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
