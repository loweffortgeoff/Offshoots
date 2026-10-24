import Testing
@testable import Offshoots

@MainActor
struct ReflectionOutputTests {
    @Test func invalidOptionalModelEvidenceKeepsTheCalculatedTimeline() throws {
        guard #available(iOS 26, *) else { return }
        let d = Make.decision(actual: .bad, notes: "Original", reflection: "Later")
        let snapshot = ReflectionSourceSnapshot.capture(decisions: [d], subjectID: d.id)
        let generated = LiveReflectionService.GeneratedDecisionChange(change: "Unsupported", earlierSource: "missing", laterSource: "missing")
        let output = LiveReflectionService.decisionOutput(generated, subject: d, snapshot: snapshot)
        #expect(output.summary == DecisionReflectionOutput.timeline(d))
        #expect(output.observations.isEmpty)
    }


    private func line(_ label: String, _ text: String) -> ReflectionGroupLine {
        ReflectionGroupLine(label: label, text: text)
    }

    @Test func patternsDropBlanksAndRepeats() throws {
        let output = try PatternsOutput(lines: [
            line("Went worse", "Decided in a hurry."), line("Went as predicted", " "), line("Went better", "Decided in a hurry. "),
        ]).validated()
        #expect(output.lines == [line("Went worse", "Decided in a hurry.")])
    }

    /// A broken run once split one sentence into "and" and "."
    @Test func patternsDropFragments() throws {
        let output = try PatternsOutput(lines: [
            line("Went worse", "You acted in a hurry."), line("Went as predicted", "and"), line("Went better", "Too short"),
        ]).validated()
        #expect(output.lines == [line("Went worse", "You acted in a hurry.")])
    }

    /// Openings seen in the live harness on 2026-10-05. The label above already names the group.
    @Test(arguments: [
        ("The notes on decisions that went worse than predicted all mention actions taken quickly or under pressure.",
         "Actions taken quickly or under pressure."),
        ("The notes on decisions that went better than predicted all involve unexpected positive results from effort or patience.",
         "Unexpected positive results from effort or patience."),
        ("The notes in the worse-than-predicted group all mention a quick decision made under pressure.",
         "A quick decision made under pressure."),
        ("The notes on decisions that went as predicted all describe clear steps taken before the outcome was known.",
         "Clear steps taken before the outcome was known."),
        ("All of these decisions were made quickly, often under pressure.",
         "Made quickly, often under pressure."),
        ("All of these decisions involved waiting or patience before acting.",
         "Waiting or patience before acting."),
    ])
    func groupOpeningIsRemoved(text: String, expected: String) {
        #expect(ReflectionText.dropGroupOpening(text) == expected)
    }

    @Test func otherSentencesAreLeftAlone() {
        #expect(ReflectionText.dropGroupOpening("Agreed right away because they asked nicely.") == "Agreed right away because they asked nicely.")
        // Too little left after the cut
        #expect(ReflectionText.dropGroupOpening("The notes all mention deadlines.") == "The notes all mention deadlines.")
    }

    @Test func validationRemovesTheOpening() throws {
        let output = try PatternsOutput(lines: [line("Went worse", "The notes on decisions that went worse than predicted all mention a rush to buy.")]).validated()
        #expect(output.lines == [line("Went worse", "A rush to buy.")])
    }

    /// Seen on build 7 (2026-10-09): with one decision in a group, the model copied its input line back.
    @Test(arguments: [
        (#"[Medium] Put off email Response. Notes: "…" Outcome note: "…""#, "Put off email Response."),
        (#"[High] Took the Denver job. Notes: "Decided over a weekend." Outcome note: "The move cost more than planned.""#,
         "Took the Denver job."),
        (#"[Low] Skipped the gym class. Outcome note: "Felt fine.""#, "Skipped the gym class."),
    ])
    func promptLeftoversAreRemoved(text: String, expected: String) {
        #expect(ReflectionText.dropPromptLeftovers(text) == expected)
    }

    @Test func sentencesWithNoLeftoversAreLeftAlone() {
        let text = "Agreed right away because they asked nicely, and the notes say it felt rushed."
        #expect(ReflectionText.dropPromptLeftovers(text) == text)
    }

    @Test func lookBackValidationRemovesPromptLeftovers() {
        let stats = LookBackStats(category: "Work", pairs: [OutcomePair(expected: .good, actual: .bad)])
        let output = LookBackOutput(stats: stats, lines: [
            line("Went worse", #"[Medium] Put off email Response. Notes: "…" Outcome note: "…""#),
        ]).validated()
        #expect(output.lines == [line("Went worse", "Put off email Response.")])
    }

    /// Seen 2026-10-14 on a phone: the model copied the input line back for both groups
    @Test func lookBackDropsASentenceThatIsOnlyATitle() {
        let stats = LookBackStats(category: "Work", pairs: [OutcomePair(expected: .bad, actual: .good), OutcomePair(expected: .neutral, actual: .neutral)])
        let output = LookBackOutput(stats: stats, lines: [
            line("Went as predicted", "[Medium] Reply to that email today, not Friday."),
            line("Went better", "Waiting before acting led to a calmer result."),
        ]).validated().droppingTitleCopies(["Reply to that email today, not Friday", "Ghost PTO"])
        #expect(output.lines == [line("Went better", "Waiting before acting led to a calmer result.")])
    }

    @Test func decisionEchoIsCleanedAndMayBeEmpty() throws {
        let output = try DecisionReflectionOutput(summary: "It aged badly.", repeating: [], nextPrompt: "", echo: "  Like the gym plan.  ").validated()
        #expect(output.echo == "Like the gym plan.")
        #expect(try DecisionReflectionOutput(summary: "It aged badly.", repeating: [], nextPrompt: "", echo: " ").validated().echo == "")
    }

    @Test func lookBackKeepsTheStatsWhenNoObservationsSurvive() {
        let stats = LookBackStats(category: "Work", pairs: [OutcomePair(expected: .bad, actual: .good)])
        let output = LookBackOutput(stats: stats, lines: [
            line("Went worse", "and"),
            line("Went better", "  Planned over several weeks. "),
        ]).validated()
        #expect(output.stats == stats)
        #expect(output.lines == [line("Went better", "Planned over several weeks.")])
    }

    @Test func patternsWithNothingUsefulAreAnError() {
        #expect(throws: ReflectionError.emptyOutput) {
            try PatternsOutput(lines: []).validated()
        }
        #expect(throws: ReflectionError.emptyOutput) {
            try PatternsOutput(lines: [line("Went worse", "  "), line("Went better", "\n")]).validated()
        }
    }

    @Test func decisionReflectionNeedsASummaryButNotTheRest() throws {
        let output = try DecisionReflectionOutput(summary: " It aged well. ", repeating: ["", "Same worry each time."], nextPrompt: " ").validated()
        #expect(output.summary == "It aged well.")
        #expect(output.repeating == ["Same worry each time."])
        #expect(output.nextPrompt.isEmpty)

        #expect(throws: ReflectionError.emptyOutput) {
            try DecisionReflectionOutput(summary: "  ", repeating: ["x"], nextPrompt: "y").validated()
        }
    }

    @Test func cleanedNoteMustHaveText() throws {
        #expect(try CleanedNote(text: "  Chose the safer job. ").validated().text == "Chose the safer job.")
        #expect(throws: ReflectionError.emptyOutput) {
            try CleanedNote(text: " \n ").validated()
        }
    }

    @Test func errorsHaveReadableMessages() {
        #expect(!ReflectionError.emptyOutput.userMessage.isEmpty)
        #expect(!ReflectionError.failed.userMessage.isEmpty)
    }
}
