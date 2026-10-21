import SwiftUI

// MARK: - 暗記クイズ（赤シート）用の環境値
// 節単位で「クイズON/OFF」「出題パターン(seed)」「カテゴリ」を配り、各本文(MaskableText)が従う。

private struct QuizModeKey: EnvironmentKey { static let defaultValue = false }
private struct QuizSeedKey: EnvironmentKey { static let defaultValue = 0 }
private struct QuizCategoryKey: EnvironmentKey { static let defaultValue = "all" }

extension EnvironmentValues {
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

    let raw: String
    var size: CGFloat = 15
    var weight: Font.Weight = .regular
    var color: Color = Theme.fg
    var lineSpacingV: CGFloat = 9

    @State private var revealed: Set<Int> = []

    private static let maskRed = Color(hex: 0xD83A2E)
    /// 出題パターンで実際に隠す割合（%）
    private static let hideRatio = 62

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
    }

    private var attributed: AttributedString {
        var out = AttributedString("")
        for seg in MaskParser.parse(raw) {
            switch seg {
            case .plain(let s):
                out += markdown(s)
            case .masked(let id, let text, let cat):
                out += maskedRun(id: id, text: text, cat: cat)
            }
        }
        return out
    }

    private func maskedRun(id: Int, text: String, cat: String) -> AttributedString {
        var run = AttributedString(text)
        if isHiddenNow(id: id, cat: cat) {
            // 隠し中：赤帯（文字色＝背景色で文字を見えなくする）＋タップ用リンク
            run.foregroundColor = Self.maskRed
            run.backgroundColor = Self.maskRed
            run.link = URL(string: "mask://\(id)")
        } else if quizMode && isCandidate(id: id, cat: cat) {
            // この回の出題対象で、タップ済み（答え表示）：薄い強調
            run.foregroundColor = color
            run.backgroundColor = Theme.accent2.opacity(0.22)
        } else {
            // 出題対象外 or クイズOFF：通常表示
            run.foregroundColor = color
        }
        return run
    }

    /// クイズON・カテゴリ一致・この seed で抽選に当たった語か
    private func isCandidate(id: Int, cat: String) -> Bool {
        guard quizMode else { return false }
        guard quizCategory == "all" || quizCategory == cat else { return false }
        return pick(id: id, seed: quizSeed)
    }

    private func isHiddenNow(id: Int, cat: String) -> Bool {
        isCandidate(id: id, cat: cat) && !revealed.contains(id)
    }

    /// (id, seed) から決まる擬似乱数で出題有無を決める（同じ回では安定、別パターンで変化）
    private func pick(id: Int, seed: Int) -> Bool {
        let mixed = ((id &+ 1) &* 73856093) ^ ((seed &+ 1) &* 19349663)
        return (mixed % 100 + 100) % 100 < Self.hideRatio
    }

    private func markdown(_ s: String) -> AttributedString {
        if let a = try? AttributedString(markdown: s) { return a }
        return AttributedString(s)
    }
}
