import Testing
@testable import Offshoots

@MainActor
struct ReflectionTextTests {
    @Test func collapsesWhitespaceAndNewlines() {
        #expect(ReflectionText.clean("  a \n\n b\t c  ", limit: 50) == "a b c")
    }

    @Test func blankOrNilIsNil() {
        #expect(ReflectionText.clean(nil, limit: 50) == nil)
        #expect(ReflectionText.clean(" \n ", limit: 50) == nil)
    }

    @Test func longTextIsCutToTheLimitWithAnEllipsis() throws {
        let cut = try #require(ReflectionText.clean(String(repeating: "x", count: 10_000), limit: 140))
        #expect(cut.count == 140)
        #expect(cut.hasSuffix("…"))
    }

    @Test func textAtTheLimitIsKept() {
        let text = String(repeating: "x", count: 140)
        #expect(ReflectionText.clean(text, limit: 140) == text)
    }

    @Test func uniqueLinesDropsBlanksAndDuplicatesKeepingOrder() {
        let lines = ReflectionText.uniqueLines(["One", " ", "Two", "One ", "Three"], limit: 50)
        #expect(lines == ["One", "Two", "Three"])
    }
}
