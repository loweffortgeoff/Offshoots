import Foundation

/// Counts for the Look Back headline, count line and bars. Built in code, not by the model,
/// so the numbers are always right.
struct LookBackStats: Equatable {
    /// Below this many decisions there is no headline. Two or three decisions are not a lean.
    static let minimumForHeadline = 5
    static let minimumDecisions = 2

    let category: String
    let pairs: [OutcomePair]

    /// Every marked decision in this category, independent of notes, purchases, or the model.
    static func build(category: DecisionCategory, decisions: [Decision]) -> LookBackStats {
        let pairs = decisions
            .filter { $0.category == category }
            .compactMap { decision in
                decision.actual.map { OutcomePair(expected: decision.expected, actual: $0) }
            }
        return LookBackStats(category: category.rawValue.capitalized, pairs: pairs)
    }

    var total: Int { pairs.count }
    var worseCount: Int { pairs.filter { $0.direction < 0 }.count }
    var asPredictedCount: Int { pairs.filter { $0.direction == 0 }.count }
    var betterCount: Int { pairs.filter { $0.direction > 0 }.count }

    /// A group must hold more than half of the decisions and lead every other group by this
    /// many, so 7 better against 6 worse is not a lean.
    static let headlineMargin = 2

    /// Only for a clear lean. It counts directions and never averages them, so 6 worse and
    /// 7 better does not read as "as predicted".
    var headline: String? {
        guard total >= Self.minimumForHeadline else { return nil }
        let groups = [
            (count: betterCount, text: "Your \(category) decisions tend to beat your predictions"),
            (count: worseCount, text: "Your \(category) decisions tend to fall short of your predictions"),
            (count: asPredictedCount, text: "Your \(category) predictions tend to hold up"),
        ].sorted { $0.count > $1.count }
        guard groups[0].count * 2 > total, groups[0].count - groups[1].count >= Self.headlineMargin else { return nil }
        return groups[0].text
    }

    var summary: String {
        let parts = [
            worseCount == 0 ? nil : "\(worseCount) went worse than you predicted",
            asPredictedCount == 0 ? nil : "\(asPredictedCount) went as predicted",
            betterCount == 0 ? nil : "\(betterCount) went better",
        ].compactMap { $0 }
        let list = parts.count > 1 ? parts.dropLast().joined(separator: ", ") + " and " + parts.last! : parts.joined()
        return "Of the \(total) \(category) decisions you marked, \(list)."
    }

    /// How many decisions had each outcome, worst first. Outcomes with no decisions are left out.
    func counts(_ outcome: KeyPath<OutcomePair, DecisionOutcome>) -> [(outcome: DecisionOutcome, count: Int)] {
        DecisionOutcome.allCases.compactMap { level in
            let count = pairs.filter { $0[keyPath: outcome] == level }.count
            return count == 0 ? nil : (level, count)
        }
    }

    /// One plain line per row, for VoiceOver: "Expected: 2 Good, 1 Great."
    func spokenRow(_ title: String, _ outcome: KeyPath<OutcomePair, DecisionOutcome>) -> String {
        "\(title): " + counts(outcome).map { "\($0.count) \($0.outcome.shortLabel)" }.joined(separator: ", ") + "."
    }
}
