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

    // A案（毎回ちがう一部だけを隠す）用：本文ごとに固定のソルト
    private var salt: Int { raw.hashValue }

    var body: some View {
        Text(attributed)
            .font(.system(size: size, weight: weight))
            .foregroundColor(color)
            .lineSpacing(lineSpacingV)
            .tint(Theme.accent)   // 隠し語=リンク。既定リンク色をアクセントに（各runで上書きするので保険）
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
                // 隠し中＝空欄。文字を透明にし、淡いアクセントの下地だけ残す
                // （黒塗りの“検閲バー”でなく「ここを思い出す空欄」に見えるように）。
                out[range].foregroundColor = .clear
                out[range].backgroundColor = Theme.accent.opacity(0.20)
            } else {
                // 表示中＝その語句を淡くハイライトし「ここが出題部分だった」と分かる。
                out[range].link = nil
                out[range].foregroundColor = color
                out[range].backgroundColor = Theme.accent2.opacity(0.18)
            }
        }
        return out
    }

    /// クイズが有効で、選んだカテゴリに属する語句のうち、その回に隠す分だけを出題する。
    private func isCandidate(id: Int, cat: String) -> Bool {
        guard quizMode else { return false }
        guard quizCategory == "all" || quizCategory == cat else { return false }
        // A案：毎回ちがう約6割だけを隠す（「もう一度」で別の組み合わせになる）
        return shouldHide(id: id)
    }

    /// seed・id・本文ソルトから決まる擬似乱数で、その回に隠すかを決める（約60%）。
    /// quizSeed は「もう一度」やトグルのたびに変わるので、回ごとに顔ぶれが変わる。
    private func shouldHide(id: Int) -> Bool {
        var h = UInt64(bitPattern: Int64((id &+ 1) &* 2654435761))
        h ^= UInt64(bitPattern: Int64((quizSeed &+ 1) &* 40503))
        h ^= UInt64(bitPattern: Int64(salt))
        h = h &* 0x9E3779B97F4A7C15
        h ^= (h >> 29)
        return Int(h % 100) < 60
    }

    private func isHiddenNow(id: Int, cat: String) -> Bool {
        isCandidate(id: id, cat: cat) && !quizAnswersVisible && !revealed.contains(id)
    }

    private func markdown(_ s: String) -> AttributedString {
        if let a = try? AttributedString(markdown: s) { return a }
        return AttributedString(s)
    }
}
