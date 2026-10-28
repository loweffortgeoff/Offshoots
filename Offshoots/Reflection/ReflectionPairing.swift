//
//  ReflectionPairing.swift
//  Offshoots
//

import Foundation
import NaturalLanguage

/// Two written notes from two different decisions that a Patterns reading may compare.
struct ReflectionPair: Equatable {
    let firstKey: String
    let secondKey: String
    /// 0 to 1, from the note text alone
    let similarity: Double
    let score: Double
    /// Recorded facts both decisions share, for the prompt: never the model's guess
    let reasons: [String]
}

/// Code, not the model, chooses which decisions a Patterns reading compares. With the whole
/// journal in front of it, the on-device model paired notes that did not match (2026-10-28
/// harness: a careful plumber hire with an angry reply). Here the pair is ranked by how alike
/// the two notes read, then by a shared result direction and a shared Hindsight answer. The
/// model only words what the two notes share, or leaves it empty.
enum ReflectionPairing {
    /// Below this the notes do not read alike, whatever else the decisions share
    static let minimumSimilarity = 0.5
    static let similarityWeight = 3.0

    static func pairs(in snapshot: ReflectionSourceSnapshot,
                      similarity makeSimilarity: ([String]) -> (String, String) -> Double = NoteSimilarity.make) -> [ReflectionPair] {
        let notes = writtenNotes(in: snapshot)
        let similarity = makeSimilarity(notes.map(\.text))
        let byID = Dictionary(snapshot.decisions.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var best: [String: ReflectionPair] = [:]
        for (i, a) in notes.enumerated() {
            for b in notes[(i + 1)...] where a.decisionID != b.decisionID {
                guard let first = byID[a.decisionID], let second = byID[b.decisionID] else { continue }
                let value = similarity(a.text, b.text)
                guard value >= minimumSimilarity else { continue }
                let reasons = sharedFacts(first, second)
                let pair = ReflectionPair(firstKey: a.key, secondKey: b.key, similarity: value,
                                          score: similarityWeight * value + Double(reasons.count), reasons: reasons)
                // One pair per two decisions: the two notes that read most alike
                let decisions = [a.decisionID.uuidString, b.decisionID.uuidString].sorted().joined()
                if let kept = best[decisions], kept.score >= pair.score { continue }
                best[decisions] = pair
            }
        }
        return best.values.sorted { $0.score == $1.score ? $0.firstKey + $0.secondKey < $1.firstKey + $1.secondKey : $0.score > $1.score }
    }

    /// Only the two chosen notes, each with its decision's title. With the whole record in front
    /// of it, the model described outcomes and days instead of what the notes say (2026-10-28).
    static func promptLines(for pair: ReflectionPair, in snapshot: ReflectionSourceSnapshot) -> String {
        let byID = Dictionary(snapshot.decisions.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let notes = Dictionary(writtenNotes(in: snapshot).map { ($0.key, $0) }, uniquingKeysWith: { first, _ in first })
        return [pair.firstKey, pair.secondKey].compactMap { key in
            guard let note = notes[key], let title = byID[note.decisionID]?.title else { return nil }
            return "[\(key)] \(title): \(note.text)"
        }.joined(separator: "\n")
    }

    // MARK: - Helpers

    private struct Note { let key: String; let decisionID: UUID; let text: String }

    private static func writtenNotes(in snapshot: ReflectionSourceSnapshot) -> [Note] {
        snapshot.evidence.filter(\.containsWrittenNote).map { item in
            // A revisit's evidence text starts with its rating ("Good: ...")
            let text = item.stage == .revisit ? String(item.text.split(separator: ":", maxSplits: 1).last ?? "") : item.text
            return Note(key: item.key, decisionID: item.decisionID, text: text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private static func sharedFacts(_ a: Decision, _ b: Decision) -> [String] {
        var facts: [String] = []
        let directions = [a, b].map { (AnalyticsEngine.predictionGap(for: $0) ?? 0).signum() }
        if directions[0] == directions[1] { facts.append("both " + ReflectionPromptBuilder.resultPhrase(directions[0])) }
        let answers = [a, b].map(latestHindsight)
        if let first = answers[0], let second = answers[1], let group = hindsightGroup(first), group == hindsightGroup(second) {
            facts.append(first == second ? "both have the hindsight answer \(first.label)" : "both hindsight answers would change something")
        }
        return facts
    }

    private static func latestHindsight(_ decision: Decision) -> HindsightAnswer? {
        decision.revisits.sorted { $0.date < $1.date }.last { $0.hindsight != nil }?.hindsight ?? decision.hindsight
    }

    private static func hindsightGroup(_ answer: HindsightAnswer) -> String? {
        switch answer {
        case .sameApproach: "same"
        case .differentApproach, .differentChoice: "change"
        case .notSure: nil
        }
    }
}

/// How alike two short notes read, 0 to 1. Uses Apple's on-device sentence embedding for the
/// notes' language, and shared words when no embedding is available.
nonisolated enum NoteSimilarity {
    /// Which measure `make` chose for the last set of notes, for the harness
    nonisolated(unsafe) static var lastMeasure = ""

    static func make(for notes: [String]) -> (String, String) -> Double {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(notes.joined(separator: " "))
        guard let language = recognizer.dominantLanguage,
              let embedding = NLEmbedding.sentenceEmbedding(for: language) else {
            lastMeasure = "shared words"
            return sharedWords
        }
        lastMeasure = "sentence embedding (\(language.rawValue))"
        var vectors: [String: [Double]] = [:]
        for note in notes where vectors[note] == nil { vectors[note] = embedding.vector(for: note) }
        return { a, b in
            guard let x = vectors[a] ?? embedding.vector(for: a), let y = vectors[b] ?? embedding.vector(for: b) else { return sharedWords(a, b) }
            return cosine(x, y)
        }
    }

    static func cosine(_ x: [Double], _ y: [Double]) -> Double {
        let dot = zip(x, y).reduce(0) { $0 + $1.0 * $1.1 }
        let norms = (x.reduce(0) { $0 + $1 * $1 }).squareRoot() * (y.reduce(0) { $0 + $1 * $1 }).squareRoot()
        return norms > 0 ? max(0, dot / norms) : 0
    }

    /// Words of four letters or more that both notes use, over the words either uses
    static func sharedWords(_ a: String, _ b: String) -> Double {
        func words(_ text: String) -> Set<String> {
            Set(text.lowercased().split { !$0.isLetter }.map(String.init).filter { $0.count >= 4 })
        }
        let x = words(a), y = words(b)
        let union = x.union(y)
        return union.isEmpty ? 0 : Double(x.intersection(y).count) / Double(union.count)
    }
}
