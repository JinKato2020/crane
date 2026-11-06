import Foundation

struct StudyQuizField {
    let id: String
    let raw: String
    let terms: [String]
}

struct StudyQuizBlank: Identifiable {
    let id: String
    let fieldID: String
    let answer: String
    let category: String
    let range: NSRange
    var prompt: String {
        StudyQuiz.isFormula(answer) ? "［式？］" : (category == "num" ? "［数値？］" : "［用語？］")
    }
}

enum StudyQuiz {
    static let limit = 10
    static let perFieldLimit = 2

    static func blockID(section: String, index: Int) -> String { "\(section)/\(index)" }
    static func fieldID(_ blockID: String?, _ field: String) -> String? {
        blockID.map { "\($0)/\(field)" }
    }

    /// Must match rendered fields. Headings, introductions and examples remain clues.
    static func fields(in section: TBSection) -> [StudyQuizField] {
        var fields: [StudyQuizField] = []
        for (index, block) in section.blocks.enumerated() {
            let base = blockID(section: section.id, index: index)
            func add(_ name: String, _ raw: String) {
                fields.append(StudyQuizField(id: "\(base)/\(name)", raw: raw, terms: block.quizTerms ?? []))
            }
            switch block.type {
            case "p":
                if !["lead", "question", "answer", "reference"].contains(block.style ?? "") {
                    add("text", block.text ?? "")
                }
            case "ul", "point":
                for (i, text) in (block.items ?? []).enumerated() { add("items:\(i)", text) }
            case "table":
                for (r, row) in (block.rows ?? []).enumerated() {
                    if block.style == "numbers" {
                        add("rows:\(r):value", row.dropFirst().joined(separator: " ／ "))
                    } else {
                        let count = (block.headers ?? []).count
                        let last = count <= 2 ? min(2, row.count) : min(count, row.count)
                        if last > 0 {
                            for c in 0..<last { add("rows:\(r):\(c)", row[c]) }
                        }
                    }
                }
            default: break
            }
        }
        return fields
    }

    /// Keep legacy {{answer::category}} readable. Malformed markers remain literal text.
    static func unmarked(_ raw: String) -> (text: String, terms: [(String, String)]) {
        var rest = raw[...]
        var output = ""
        var terms: [(String, String)] = []
        while let open = rest.range(of: "{{") {
            output += rest[..<open.lowerBound]
            let after = rest[open.upperBound...]
            guard let close = after.range(of: "}}") else {
                output += rest[open.lowerBound...]
                return (output, terms)
            }
            let parts = String(after[..<close.lowerBound]).components(separatedBy: "::")
            let answer = parts[0]
            output += answer
            if !answer.isEmpty {
                terms.append((answer, parts.count > 1 && parts[1] == "num" ? "num" : "key"))
            }
            rest = after[close.upperBound...]
        }
        output += rest
        return (output, terms)
    }

    static func attributed(_ raw: String) -> AttributedString {
        let clean = unmarked(raw).text
        return (try? AttributedString(markdown: clean, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(clean)
    }

    static func key(_ answer: String) -> String {
        answer.folding(options: [.widthInsensitive, .caseInsensitive], locale: Locale(identifier: "ja_JP"))
            .filter { !$0.isWhitespace }
    }

    /// The hidden answer is absent from both visible and accessibility text, and from the link URL.
    static func presentation(_ raw: String, blanks: [StudyQuizBlank], revealed: Set<String>) -> AttributedString {
        var out = attributed(raw)
        for blank in blanks.sorted(by: { $0.range.location > $1.range.location }) {
            let plain = String(out.characters)
            guard let range = Range(blank.range, in: plain) else { continue }
            let start = out.characters.index(out.characters.startIndex, offsetBy: plain[..<range.lowerBound].count)
            let end = out.characters.index(start, offsetBy: plain[range].count)
            let visible = revealed.contains(blank.id)
            var replacement = AttributedString(visible ? blank.answer : blank.prompt)
            var url = URLComponents()
            url.scheme = "studyquiz"; url.host = "answer"
            url.queryItems = [URLQueryItem(name: "id", value: blank.id)]
            replacement.link = url.url
            replacement.inlinePresentationIntent = .stronglyEmphasized
            out.replaceSubrange(start..<end, with: replacement)
        }
        return out
    }

    static func candidates(in fields: [StudyQuizField]) -> [StudyQuizBlank] {
        var result: [StudyQuizBlank] = []
        var seen = Set<String>()
        for field in fields {
            let text = String(attributed(field.raw).characters)
            let legacy = unmarked(field.raw).terms
            let terms = Set((field.terms + legacy.map { $0.0 }).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                .sorted { $0.count == $1.count ? $0 < $1 : $0.count > $1.count }
            guard !terms.isEmpty else { continue }
            let patterns = terms.map(pattern)
            guard let regex = try? NSRegularExpression(pattern: patterns.joined(separator: "|")) else { continue }
            for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                guard let range = Range(match.range, in: text) else { continue }
                let answer = String(text[range])
                guard seen.insert(key(answer)).inserted else { continue }
                let category = legacy.first { $0.0 == answer }?.1
                    ?? (isFormula(answer) || answer.rangeOfCharacter(from: .decimalDigits) == nil ? "key" : "num")
                result.append(StudyQuizBlank(id: "\(field.id)#\(match.range.location)", fieldID: field.id,
                                            answer: answer, category: category, range: match.range))
            }
        }
        return result
    }

    static func pattern(_ term: String) -> String {
        var body = NSRegularExpression.escapedPattern(for: term)
        if term.rangeOfCharacter(from: .decimalDigits) != nil {
            body = "(?<![0-9０-９.．])(?:\(body))(?![0-9０-９.．])"
            if let last = term.unicodeScalars.last, CharacterSet.decimalDigits.contains(last) {
                body += "(?![A-Za-z％%])"
            }
        }
        let compound = "[\\u3400-\\u9fff\\u30a1-\\u30f6ー]"
        if let first = term.first, String(first).range(of: compound, options: .regularExpression) != nil {
            body = "(?<!\(compound))" + body
        }
        if let last = term.last, String(last).range(of: compound, options: .regularExpression) != nil {
            body += "(?!\(compound))"
        }
        return body
    }

    static func isFormula(_ answer: String) -> Bool {
        if answer.contains("×") || answer.contains("÷") || answer.contains("＝") { return true }
        return answer.range(of: "[A-Z][₀-₉²³]|^[A-Z]/[a-zA-Z]$", options: .regularExpression) != nil
    }

    /// Stable across launches, at most ten different answers and two blanks per text field.
    static func selection(from candidates: [StudyQuizBlank], category: String = "all", round: Int = 0) -> [StudyQuizBlank] {
        let pool = candidates.filter { category == "all" || $0.category == category }
            .sorted { a, b in
                let lhs = stableHash(a.id), rhs = stableHash(b.id)
                return lhs == rhs ? a.id < b.id : lhs < rhs
            }
        guard !pool.isEmpty else { return [] }
        let start = max(0, round) % pool.count
        var counts: [String: Int] = [:]
        var selected: [StudyQuizBlank] = []
        var usedRows = Set<String>()
        for offset in 0..<pool.count {
            let item = pool[(start + offset) % pool.count]
            guard counts[item.fieldID, default: 0] < perFieldLimit else { continue }
            // Only one blank in each table row: the other cells provide the question's clues.
            if item.fieldID.contains("/rows:"), let colon = item.fieldID.lastIndex(of: ":") {
                let row = String(item.fieldID[..<colon])
                guard usedRows.insert(row).inserted else { continue }
            }
            selected.append(item)
            counts[item.fieldID, default: 0] += 1
            if selected.count == limit { break }
        }
        return selected
    }

    private static func stableHash(_ value: String) -> UInt64 {
        value.utf8.reduce(UInt64(14695981039346656037)) { ($0 ^ UInt64($1)) &* 1099511628211 }
    }
}
