import Testing
@testable import Offshoots

@MainActor
struct ReflectionOutputTests {

    @Test func patternsDropBlanksAndRepeats() throws {
        let output = try PatternsOutput(observations: ["You lean optimistic.", " ", "You lean optimistic. ", "Money is harder."]).validated()
        #expect(output.observations == ["You lean optimistic.", "Money is harder."])
    }

    /// A broken run once split one sentence into "and" and "."
    @Test func patternsDropFragments() throws {
        let output = try PatternsOutput(observations: ["You acted in a hurry when it went worse.", "and", ".", "Too short"]).validated()
        #expect(output.observations == ["You acted in a hurry when it went worse."])
    }

    @Test func decisionEchoIsCleanedAndMayBeEmpty() throws {
        let output = try DecisionReflectionOutput(summary: "It aged badly.", repeating: [], nextPrompt: "", echo: "  Like the gym plan.  ").validated()
        #expect(output.echo == "Like the gym plan.")
        #expect(try DecisionReflectionOutput(summary: "It aged badly.", repeating: [], nextPrompt: "", echo: " ").validated().echo == "")
    }

    @Test func lookBackKeepsTheSummaryWhenNoObservationsSurvive() {
        let output = LookBackOutput(summary: "Of your last 2 Work decisions, 2 went better.", lines: [
            LookBackLine(label: "Went worse", text: "and"),
            LookBackLine(label: "Went better", text: "  These were planned over weeks. "),
        ]).validated()
        #expect(output.summary == "Of your last 2 Work decisions, 2 went better.")
        #expect(output.lines == [LookBackLine(label: "Went better", text: "These were planned over weeks.")])
    }

    @Test func patternsWithNothingUsefulAreAnError() {
        #expect(throws: ReflectionError.emptyOutput) {
            try PatternsOutput(observations: []).validated()
        }
        #expect(throws: ReflectionError.emptyOutput) {
            try PatternsOutput(observations: ["  ", "\n"]).validated()
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
