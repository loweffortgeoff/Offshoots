//
//  ReflectionText.swift
//  Offshoots
//

import Foundation

enum ReflectionText {
    /// Collapses whitespace, trims, and cuts to `limit` characters with an ellipsis.
    /// Nil when nothing is left, so blank notes never reach a prompt.
    static func clean(_ text: String?, limit: Int) -> String? {
        guard let text else { return nil }
        let collapsed = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard !collapsed.isEmpty else { return nil }
        guard collapsed.count > limit else { return collapsed }
        return String(collapsed.prefix(limit - 1)) + "…"
    }

    /// The model starts each group sentence with the group, for example "The notes on decisions
    /// that went worse than predicted all mention actions taken quickly". A label above the
    /// sentence already names the group, so this keeps "Actions taken quickly". A sentence
    /// with another opening, or too little left after the cut, comes back unchanged.
    static func dropGroupOpening(_ text: String) -> String {
        let pattern = #"^(?:the notes|these notes|the decisions|these decisions|all of these(?: decisions| notes)?)\b[^.,;:]{0,90}?\b(?:all |each |often |mostly )?(?:mention|mentions|mentioned|describe|describes|described|involve|involves|involved|share|shares|shared|show|shows|showed|include|includes|included|reflect|reflects|reflected|point to|talk about|focus on|centre on|center on|were|are)\s+"#
        guard let range = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) else { return text }
        let rest = text[range.upperBound...]
        guard rest.split(whereSeparator: \.isWhitespace).count >= PatternsOutput.minimumWords else { return text }
        return rest.prefix(1).uppercased() + rest.dropFirst()
    }

    /// Cleaned, non-blank lines with repeats removed, in first-seen order.
    /// A `ForEach` can use the line itself as its id because lines are unique.
    static func uniqueLines(_ lines: [String], limit: Int) -> [String] {
        var seen = Set<String>()
        return lines.compactMap { clean($0, limit: limit) }.filter { seen.insert($0).inserted }
    }
}
