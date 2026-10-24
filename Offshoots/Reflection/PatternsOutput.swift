import Foundation

struct PatternsOutput: Codable, Equatable {
    var lines: [ReflectionGroupLine] = [] // Dormant legacy format; never saved by the new controller.
    var observations: [ReflectionObservation] = []
    static let minimumWords = 3
    func validated() throws -> Self {
        let kept = ReflectionGroupLine.validated(lines)
        guard !kept.isEmpty || !observations.isEmpty else { throw ReflectionError.emptyOutput }
        return Self(lines: kept, observations: observations)
    }
}
