import Testing
@testable import Offshoots

@MainActor
struct ReflectionOutputTests {

    @Test func patternsDropBlanksAndRepeats() throws {
        let output = try PatternsOutput(observations: ["You lean optimistic.", " ", "You lean optimistic. ", "Money is harder."]).validated()
        #expect(output.observations == ["You lean optimistic.", "Money is harder."])
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
