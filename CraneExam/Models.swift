import Foundation

/// 科目免除のない学科試験。案内と模試で同じ時間を表示する。
enum CraneExamFormat {
    static let durationMinutes = 150
    static let durationLabel = "2時間30分"
    static let durationSeconds = durationMinutes * 60
}

/// バックグラウンド中も開始時刻との差で測る。タイマーの通知回数には依存しない。
struct MockExamClock {
    let limited: Bool
    let startedAt: Date

    func elapsedSeconds(at date: Date) -> Int {
        let seconds = max(0, Int(date.timeIntervalSince(startedAt)))
        return limited ? min(seconds, CraneExamFormat.durationSeconds) : seconds
    }

    func remainingSeconds(at date: Date) -> Int {
        max(0, CraneExamFormat.durationSeconds - elapsedSeconds(at: date))
    }

    func hasExpired(at date: Date) -> Bool {
        limited && date.timeIntervalSince(startedAt) >= Double(CraneExamFormat.durationSeconds)
    }
}

/// 未回答も科目ごとの分母に含める。解答は問題番号ごとに一度だけ採点する。
struct MockExamScore {
    let result: ExamResult
    let wrongRefs: [WrongRef]

    init(exam: Exam, answers: [Int: Int], elapsed: Int, date: Date = Date()) {
        var correct = 0
        var subjects: [String: [Int]] = [:]
        var wrong: [WrongRef] = []
        for question in exam.questions {
            var counts = subjects[question.subject] ?? [0, 0]
            counts[1] += 1
            if answers[question.no] == question.answer - 1 {
                correct += 1
                counts[0] += 1
            } else {
                wrong.append(WrongRef(round: exam.round, no: question.no, subject: question.subject))
            }
            subjects[question.subject] = counts
        }
        result = ExamResult(round: exam.round, date: date, correct: correct,
                            total: exam.questions.count, perSubject: subjects, elapsed: elapsed)
        wrongRefs = wrong
    }
}

/// 1回分の模擬試験
struct Exam: Codable, Identifiable {
    let round: Int
    let title: String
    let questions: [Question]
    var id: Int { round }
}

/// 1問
struct Question: Codable, Identifiable {
    let no: Int
    /// 表示番号と保存用IDを分離し、科目順の変更で既存のしおり・誤答履歴をずらさない。
    let displayNo: Int?
    let subject: String
    let text: String
    let choices: [String]
    let choiceHeaders: [String]?
    let choiceRows: [[String]]?
    let answer: Int          // 1始まりの正解番号
    let explanation: String
    let figure: String?      // 旧ASCII図（現在は未使用）
    let figImg: String?      // 回答前の図アセット名（条件図）
    let figImgExp: String?   // 回答後の図アセット名（解説図）
    let ref: TextRef?        // 関連する教材へのピンポイント直リンク（任意）
    let refs: [TextRef]?     // 複数の根拠を参照。refは旧データ・旧アプリ用に維持
    var textbookReferences: [TextRef] {
        let candidates: [TextRef]
        if let refs, !refs.isEmpty { candidates = refs }
        else if let ref { candidates = [ref] }
        else { candidates = [] }
        var seen = Set<String>()
        return candidates.filter { seen.insert($0.id).inserted }
    }
    var id: Int { no }
    var numberForDisplay: Int { displayNo ?? no }
}

/// 問題の解説から教材へ直リンクするための参照。
/// section = 節ID（例 "4-1"）、anchor = その節内の小見出し等のキーワード（例 "モーメント"）。
/// anchor があれば、その位置まで自動スクロールして示す。
struct TextRef: Codable, Identifiable {
    let section: String
    let blockID: String?     // 文言・並び順の変更でずれない教材ブロックID
    let anchor: String?
    let label: String?       // ボタンに出す補足（例 "力のモーメント"）
    var id: String { [section, blockID ?? "", anchor ?? ""].joined(separator: "|") }
}

/// 受験結果（端末内に保存）
struct ExamResult: Codable, Identifiable {
    let round: Int
    let date: Date
    let correct: Int
    let total: Int
    let perSubject: [String: [Int]]   // 分野 -> [正答, 出題]
    let elapsed: Int                  // 秒
    var id: String { "\(round)-\(Int(date.timeIntervalSince1970))" }
    var percent: Int { total == 0 ? 0 : Int((Double(correct) / Double(total) * 100).rounded()) }
    var examScore: Int {
        let weights = ["クレーンに関する知識": 3, "原動機・電気": 3, "力学": 2, "関係法令": 2]
        return weights.reduce(0) { points, entry in
            points + (perSubject[entry.key]?.first ?? 0) * entry.value
        }
    }
    var meetsSubjectMinimums: Bool {
        SUBJECTS.allSatisfy { subject in
            guard let counts = perSubject[subject], counts.count == 2, counts[1] > 0 else { return false }
            return counts[0] * 100 >= counts[1] * 40
        }
    }
    var isPassing: Bool { examScore >= 60 && meetsSubjectMinimums }
}

/// 間違えた問題の記録
struct WrongRef: Codable, Identifiable, Hashable {
    let round: Int
    let no: Int
    let subject: String
    var id: String { "\(round)-\(no)" }
}

let SUBJECTS = ["クレーンに関する知識", "原動機・電気", "力学", "関係法令"]

func subjectShort(_ s: String) -> String {
    switch s {
    case "クレーンに関する知識": return "構造"
    case "原動機・電気": return "原動機"
    case "力学": return "力学"
    case "関係法令": return "法令"
    default: return s
    }
}
