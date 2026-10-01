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

    /// Cleaned, non-blank lines with repeats removed, in first-seen order.
    /// A `ForEach` can use the line itself as its id because lines are unique.
    static func uniqueLines(_ lines: [String], limit: Int) -> [String] {
        var seen = Set<String>()
        return lines.compactMap { clean($0, limit: limit) }.filter { seen.insert($0).inserted }
    }
}
