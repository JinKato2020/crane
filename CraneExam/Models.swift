import Foundation

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
    let subject: String
    let text: String
    let choices: [String]
    let answer: Int          // 1始まりの正解番号
    let explanation: String
    let figure: String?      // ASCII図（あれば）
    var id: Int { no }
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
