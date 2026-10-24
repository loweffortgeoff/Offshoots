import Testing
@testable import Offshoots

@MainActor
struct ReflectionVisibilityTests {
    @Test func savedContentDoesNotDependOnGenerationAccess() {
        for gate in [ReflectionSurfaceState.hidden,.paywalled,.notReady(reason: "Unavailable"),.enabled] {
            #expect(ReflectionVisibility.showEntry(gate: gate, savedCount: 1))
        }
        #expect(!ReflectionVisibility.showEntry(gate: .hidden, savedCount: 0))
        #expect(ReflectionVisibility.showEntry(gate: .enabled, savedCount: 0))
    }
}
