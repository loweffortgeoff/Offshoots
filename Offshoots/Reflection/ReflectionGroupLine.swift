import Foundation

struct ReflectionGroupLine: Codable, Equatable {
    var label: String
    var text: String

    static let worseLabel = "Went worse"
    static let asPredictedLabel = "Went as predicted"
    static let betterLabel = "Went better"
}


extension ReflectionGroupLine {
    /// Cleans each sentence. Drops blanks, fragments and a sentence that repeats an earlier one.
    static func validated(_ lines: [ReflectionGroupLine]) -> [ReflectionGroupLine] {
        var seen = Set<String>()
        return lines.compactMap { line in
            guard let text = ReflectionText.clean(line.text, limit: 400).map(ReflectionText.dropPromptLeftovers).map(ReflectionText.dropGroupOpening),
                  text.split(whereSeparator: \.isWhitespace).count >= PatternsOutput.minimumWords,
                  seen.insert(text).inserted
            else { return nil }
            return ReflectionGroupLine(label: line.label, text: text)
        }
    }
}

