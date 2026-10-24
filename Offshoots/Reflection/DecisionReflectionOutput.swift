import Foundation

struct DecisionReflectionOutput: Codable, Equatable {
    var summary: String
    var repeating: [String] = [] // Legacy, retained only for compatibility tests.
    var nextPrompt: String = ""
    var echo: String = ""
    var observations: [ReflectionObservation] = []
    func validated() throws -> Self {
        guard let summary = ReflectionText.clean(summary, limit: 600) else { throw ReflectionError.emptyOutput }
        return Self(summary: summary, repeating: ReflectionText.uniqueLines(repeating, limit: 400),
                    nextPrompt: ReflectionText.clean(nextPrompt, limit: 300) ?? "",
                    echo: ReflectionText.clean(echo, limit: 400) ?? "", observations: observations)
    }
    static func timeline(_ decision: Decision) -> String {
        var lines = ["You predicted \(decision.expected.shortLabel). Your first outcome was \(decision.actual?.shortLabel ?? "unmarked")."]
        for revisit in decision.revisits.sorted(by: { $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date < $1.date }) {
            lines.append("On \(revisit.date.formatted(date: .abbreviated, time: .omitted)), you rated it \(revisit.outcome.shortLabel).")
        }
        return lines.joined(separator: " ")
    }
}
