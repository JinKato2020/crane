import SwiftUI

private struct QuizModeKey: EnvironmentKey { static let defaultValue = false }
private struct StudyQuizSessionKey: EnvironmentKey { static let defaultValue: StudyQuizSession? = nil }

extension EnvironmentValues {
    var quizMode: Bool { get { self[QuizModeKey.self] } set { self[QuizModeKey.self] = newValue } }
    var studyQuizSession: StudyQuizSession? {
        get { self[StudyQuizSessionKey.self] }
        set { self[StudyQuizSessionKey.self] = newValue }
    }
}

/// One session per section: individual taps and the answer toolbar always agree.
final class StudyQuizSession: ObservableObject {
    let candidates: [StudyQuizBlank]
    @Published var isOn = false { didSet { revealed.removeAll() } }
    @Published var category = "all" { didSet { round = 0; refresh() } }
    @Published private(set) var selected: [StudyQuizBlank] = []
    @Published private(set) var revealed = Set<String>()
    private var round = 0

    init(section: TBSection) {
        candidates = StudyQuiz.candidates(in: StudyQuiz.fields(in: section))
        refresh()
    }

    var categories: [String] {
        ["all", "key", "num"].filter { cat in cat == "all" || candidates.contains { $0.category == cat } }
    }
    var allRevealed: Bool { !selected.isEmpty && revealed.count == selected.count }
    var canChange: Bool {
        candidates.filter { category == "all" || $0.category == category }.count > selected.count
    }
    var answerLabel: String {
        allRevealed ? "もう一度隠す" : (revealed.isEmpty ? "答えを表示" : "残りの答えを表示")
    }

    func toggle(_ id: String) {
        guard isOn, selected.contains(where: { $0.id == id }) else { return }
        if revealed.contains(id) { revealed.remove(id) } else { revealed.insert(id) }
    }
    func toggleAll() {
        if allRevealed { revealed.removeAll() } else { revealed = Set(selected.map(\.id)) }
    }
    func nextRound() {
        let previous = Set(selected.map(\.id))
        for _ in 0..<max(1, candidates.count) {
            round += 1
            let next = StudyQuiz.selection(from: candidates, category: category, round: round)
            if Set(next.map(\.id)) != previous { selected = next; revealed.removeAll(); return }
        }
        revealed.removeAll()
    }
    private func refresh() {
        selected = StudyQuiz.selection(from: candidates, category: category, round: round)
        revealed.removeAll()
    }
}

/// Ordinary Markdown outside a quiz. Selection belongs to the whole section.
struct MaskableText: View {
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.quizMode) private var quizMode
    @Environment(\.studyQuizSession) private var session
    let raw: String
    var terms: [String] = [] // Source compatibility; candidates are collected by StudyQuiz.
    var quizField: String? = nil
    var size: CGFloat = 15
    var weight: Font.Weight = .regular
    var color: Color = Theme.fg
    var lineSpacingV: CGFloat = 9

    var body: some View {
        Group {
            if quizMode, let session = session, let field = quizField {
                QuizFieldText(raw: raw, fieldID: field, session: session)
            } else {
                Text(Self.emphasized(raw))
            }
        }
        .font(.system(size: size * textScale, weight: weight))
        .foregroundColor(color)
        .tint(Theme.studyKey)
        .lineSpacing(lineSpacingV)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    static func emphasized(_ raw: String) -> AttributedString {
        emphasized(StudyQuiz.attributed(raw))
    }

    static func emphasized(_ value: AttributedString) -> AttributedString {
        var out = value
        for run in Array(out.runs) where run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
            out[run.range].foregroundColor = Theme.studyKey
            out[run.range].backgroundColor = Theme.studyKey.opacity(0.09)
        }
        return out
    }
}

private struct QuizFieldText: View {
    let raw: String
    let fieldID: String
    @ObservedObject var session: StudyQuizSession

    var body: some View {
        Text(attributed)
            .environment(\.openURL, OpenURLAction { url in
                guard url.scheme == "studyquiz", let value = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "id" })?.value else { return .systemAction }
                session.toggle(value)
                return .handled
            })
    }

    private var attributed: AttributedString {
        let blanks = session.selected.filter { $0.fieldID == fieldID }
        var out = MaskableText.emphasized(StudyQuiz.presentation(raw, blanks: blanks, revealed: session.revealed))
        for run in Array(out.runs) {
            guard let url = run.link, url.scheme == "studyquiz",
                  let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?
                    .first(where: { $0.name == "id" })?.value else { continue }
            out[run.range].foregroundColor = Theme.studyKey
            out[run.range].backgroundColor = Theme.studyKey.opacity(session.revealed.contains(id) ? 0.08 : 0.16)
        }
        return out
    }
}
