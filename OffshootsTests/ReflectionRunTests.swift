import Testing
@testable import Offshoots

@MainActor
struct ReflectionRunTests {

    @Test func startsIdle() {
        #expect(ReflectionRun<String>().state == .idle)
    }

    @Test func successShowsTheResult() async {
        let run = ReflectionRun<String>()
        let task = run.start { "done" }
        #expect(run.state == .loading)
        await task.value
        #expect(run.state == .result("done"))
    }

    @Test func aReflectionErrorShowsItsOwnMessage() async {
        let run = ReflectionRun<String>()
        await run.start { throw ReflectionError.emptyOutput }.value
        #expect(run.state == .error(ReflectionError.emptyOutput.userMessage))
    }

    @Test func anyOtherErrorShowsTheGenericMessage() async {
        struct Boom: Error {}
        let run = ReflectionRun<String>()
        await run.start { throw Boom() }.value
        #expect(run.state == .error(ReflectionError.failed.userMessage))
    }

    @Test func aNewerStartWinsOverASlowerOlderOne() async {
        let run = ReflectionRun<String>()
        let first = run.start {
            try await Task.sleep(for: .milliseconds(50))
            return "old"
        }
        let second = run.start { "new" }
        await first.value
        await second.value
        #expect(run.state == .result("new"))
    }

    @Test func resetCancelsAndReturnsToIdle() async {
        let run = ReflectionRun<String>()
        let task = run.start {
            try await Task.sleep(for: .milliseconds(50))
            return "late"
        }
        run.reset()
        await task.value
        #expect(run.state == .idle)
    }
}
