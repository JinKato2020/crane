import SwiftUI

// MARK: - 暗記クイズ（赤シート）用の環境値
// 節単位で「クイズON/OFF」「出題パターン(seed)」「カテゴリ」を配り、各本文(MaskableText)が従う。

private struct QuizModeKey: EnvironmentKey { static let defaultValue = false }
private struct QuizSeedKey: EnvironmentKey { static let defaultValue = 0 }
private struct QuizCategoryKey: EnvironmentKey { static let defaultValue = "all" }
private struct QuizAnswersKey: EnvironmentKey { static let defaultValue = false }

extension EnvironmentValues {
    var quizAnswersVisible: Bool { get { self[QuizAnswersKey.self] } set { self[QuizAnswersKey.self] = newValue } }
    var quizMode: Bool { get { self[QuizModeKey.self] } set { self[QuizModeKey.self] = newValue } }
    var quizSeed: Int { get { self[QuizSeedKey.self] } set { self[QuizSeedKey.self] = newValue } }
    var quizCategory: String { get { self[QuizCategoryKey.self] } set { self[QuizCategoryKey.self] = newValue } }
}

// MARK: - 本文の {{ }} をパースする

enum MaskSeg {
    case plain(String)
    case masked(id: Int, text: String, cat: String)
}

enum MaskParser {
    /// 本文に {{ }} が含まれるか（トグル表示の判定に使う）
    static func hasMask(_ s: String?) -> Bool { (s ?? "").contains("{{") }

    /// {{語句}} / {{語句::num}} を分解。cat 既定は "key"(用語)。
    static func parse(_ raw: String) -> [MaskSeg] {
        var segs: [MaskSeg] = []
        var id = 0
        var rest = Substring(raw)
        while let open = rest.range(of: "{{") {
            let before = rest[rest.startIndex..<open.lowerBound]
            if !before.isEmpty { segs.append(.plain(String(before))) }
            let afterOpen = rest[open.upperBound...]
            guard let close = afterOpen.range(of: "}}") else {
                segs.append(.plain(String(afterOpen)))
                return segs
            }
            let inner = String(afterOpen[afterOpen.startIndex..<close.lowerBound])
            let parts = inner.components(separatedBy: "::")
            let text = parts.first ?? ""
            let cat = parts.count > 1 ? parts[1] : "key"
            segs.append(.masked(id: id, text: text, cat: cat))
            id += 1
            rest = afterOpen[close.upperBound...]
        }
        if !rest.isEmpty { segs.append(.plain(String(rest))) }
        return segs
    }
}

// MARK: - 赤シート表示の本文

/// {{ }} で囲まれた語句を、クイズON時に赤い帯で隠す。1語ずつタップで解除。
/// クイズOFF時は従来の Text(markdown) と同じ見た目で描く。
struct MaskableText: View {
    @Environment(\.quizMode) private var quizMode
    @Environment(\.quizSeed) private var quizSeed
    @Environment(\.quizCategory) private var quizCategory
    @Environment(\.quizAnswersVisible) private var quizAnswersVisible

    let raw: String
    var terms: [String] = []
    var size: CGFloat = 15
    var weight: Font.Weight = .regular
    var color: Color = Theme.fg
    var lineSpacingV: CGFloat = 9

    @State private var revealed: Set<Int> = []

    private static let maskRed = Color(hex: 0xD83A2E)

    var body: some View {
        Text(attributed)
            .font(.system(size: size, weight: weight))
            .foregroundColor(color)
            .lineSpacing(lineSpacingV)
            .tint(Self.maskRed)   // 隠し語=リンクなので tint を赤にして帯を赤一色に
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.openURL, OpenURLAction { url in
                if url.scheme == "mask", let h = url.host, let i = Int(h) {
                    revealed.insert(i)
                    return .handled
                }
                return .systemAction
            })
            .onChange(of: quizSeed) { _ in revealed.removeAll() }
            .onChange(of: quizMode) { _ in revealed.removeAll() }
            .onChange(of: quizCategory) { _ in revealed.removeAll() }
            .onChange(of: quizAnswersVisible) { visible in
                if !visible { revealed.removeAll() }
            }
    }

    private var attributed: AttributedString {
        var source = raw
        if !MaskParser.hasMask(source), !terms.isEmpty {
            let pattern = terms.sorted { $0.count > $1.count }
                .map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: source, range: NSRange(source.startIndex..., in: source))
                for match in matches.reversed() {
                    if let range = Range(match.range, in: source) {
                        let word = String(source[range])
                        let cat = word.rangeOfCharacter(from: .decimalDigits) == nil ? "key" : "num"
                        source.replaceSubrange(range, with: "{{\(word)::\(cat)}}")
                    }
                }
            }
        }
        var formatted = ""
        var candidates: [Int: String] = [:]
        for seg in MaskParser.parse(source) {
            switch seg {
            case .plain(let s):
                formatted += s
            case .masked(let id, let text, let cat):
                if isCandidate(id: id, cat: cat) {
                    formatted += "[\(text)](mask://\(id))"
                    candidates[id] = cat
                } else { formatted += text }
            }
        }
        var out = markdown(formatted)
        for run in Array(out.runs) {
            guard let url = run.link, url.scheme == "mask", let host = url.host,
                  let id = Int(host), let cat = candidates[id] else { continue }
            let range = run.range
            if isHiddenNow(id: id, cat: cat) {
                out[range].foregroundColor = Self.maskRed
                out[range].backgroundColor = Self.maskRed
            } else {
                out[range].link = nil
                out[range].foregroundColor = color
                out[range].backgroundColor = Theme.accent2.opacity(0.22)
            }
        }
        return out
    }

    /// クイズが有効で、選んだカテゴリに属する語句をすべて出題する。
    private func isCandidate(id: Int, cat: String) -> Bool {
        guard quizMode else { return false }
        guard quizCategory == "all" || quizCategory == cat else { return false }
        return true
    }

    private func isHiddenNow(id: Int, cat: String) -> Bool {
        isCandidate(id: id, cat: cat) && !quizAnswersVisible && !revealed.contains(id)
    }

    private func markdown(_ s: String) -> AttributedString {
        if let a = try? AttributedString(markdown: s) { return a }
        return AttributedString(s)
    }
}
