import Foundation

/// One marked decision: what the user predicted, and the first result they marked.
struct OutcomePair: Equatable {
    let expected: DecisionOutcome
    let actual: DecisionOutcome

    /// -1 worse than predicted, 0 as predicted, 1 better. The same sign as `predictionGap`.
    var direction: Int { (actual.numericValue - expected.numericValue).signum() }
}
