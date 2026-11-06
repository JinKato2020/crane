import Foundation

@main
struct VerifyStudyQuiz {
    static func main() throws {
        let raw = "🏗️ **荷重試験は1.25倍**、安定度試験は**1.27倍**。"
        let fields = [StudyQuizField(id: "unicode", raw: raw, terms: ["1.25倍", "1.27倍", ""])]
        let blanks = StudyQuiz.candidates(in: fields)
        precondition(blanks.count == 2)
        let hidden = StudyQuiz.presentation(raw, blanks: blanks, revealed: [])
        let hiddenText = String(hidden.characters)
        precondition(hiddenText == "🏗️ 荷重試験は［数値？］、安定度試験は［数値？］。")
        precondition(!hiddenText.contains("1.25") && !hiddenText.contains("1.27"))
        let one = StudyQuiz.presentation(raw, blanks: blanks, revealed: [blanks[0].id])
        precondition(String(one.characters) == "🏗️ 荷重試験は1.25倍、安定度試験は［数値？］。")
        let restored = StudyQuiz.presentation(raw, blanks: blanks, revealed: Set(blanks.map(\.id)))
        precondition(String(restored.characters) == String(StudyQuiz.attributed(raw).characters))
        precondition(restored.runs.filter { $0.link?.scheme == "studyquiz" }.count == 2, "Revealed answers stay tappable")
        for run in hidden.runs where run.link != nil {
            precondition(!(run.link?.absoluteString.contains("1.25") ?? true))
        }
        let splitBold = StudyQuizField(id: "bold", raw: "各枝は**電圧**が同じ。", terms: ["電圧が同じ"])
        let split = StudyQuiz.candidates(in: [splitBold])
        precondition(split.count == 1)
        precondition(String(StudyQuiz.presentation(splitBold.raw, blanks: split, revealed: []).characters) == "各枝は［用語？］。")

        let legacy = "前{{3年::num}}・{{合力::trap}}・{{未完"
        precondition(StudyQuiz.unmarked(legacy).text == "前3年・合力・{{未完")
        let old = StudyQuiz.candidates(in: [StudyQuizField(id: "old", raw: legacy, terms: [])])
        precondition(old.map(\.category) == ["num", "key"])

        for (term, text) in [("速度", "加速度"), ("導体", "半導体"), ("5t", "15t"),
                             ("1", "10"), ("7.8", "7.8t/m³"), ("静止摩擦力", "最大静止摩擦力")] {
            precondition(StudyQuiz.candidates(in: [StudyQuizField(id: "boundary", raw: text, terms: [term])]).isEmpty)
        }
        let punctuation = StudyQuiz.candidates(in: [StudyQuizField(id: "regex", raw: "式は R₁×R₂÷（R₁＋R₂）。比は1/√3。", terms: ["R₁×R₂÷（R₁＋R₂）", "1/√3"])])
        precondition(!StudyQuiz.isFormula("9.8m/s²") && !StudyQuiz.isFormula("400N/mm²以上"))
        precondition(punctuation.count == 2)
        precondition(punctuation[0].prompt == "［式？］" && punctuation[1].prompt == "［数値？］")
        let duplicated = StudyQuiz.candidates(in: fields + [StudyQuizField(id: "again", raw: raw, terms: fields[0].terms)])
        precondition(duplicated.count == 2)
        precondition(StudyQuiz.selection(from: [], category: "num").isEmpty)
        precondition(StudyQuiz.selection(from: [blanks[0]]).count == 1)

        let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "CraneExam/Resources")
        let textbook = try JSONDecoder().decode(Textbook.self, from: Data(contentsOf: root.appendingPathComponent("textbook.json")))
        var total = 0
        for section in textbook.chapters.flatMap(\.sections) {
            let fields = StudyQuiz.fields(in: section)
            let pool = StudyQuiz.candidates(in: fields)
            total += pool.count
            precondition(Set(pool.map { StudyQuiz.key($0.answer) }).count == pool.count)
            for category in ["all", "num", "key"] {
                let available = pool.filter { category == "all" || $0.category == category }
                var reached = Set<String>()
                var rounds = Set<Set<String>>()
                for round in 0..<max(1, available.count) {
                    let selection = StudyQuiz.selection(from: pool, category: category, round: round)
                    precondition(selection.count <= 10 && selection.isEmpty == available.isEmpty)
                    precondition(selection.allSatisfy { category == "all" || $0.category == category })
                    precondition(Dictionary(grouping: selection, by: \.fieldID).values.allSatisfy { $0.count <= 2 })
                    let rows = selection.filter { $0.fieldID.contains("/rows:") }.map { String($0.fieldID[..<$0.fieldID.lastIndex(of: ":")!]) }
                    precondition(Set(rows).count == rows.count)
                    let ids = Set(selection.map(\.id))
                    rounds.insert(ids); reached.formUnion(ids)
                    precondition(ids == Set(StudyQuiz.selection(from: pool, category: category, round: round).map(\.id)))
                }
                precondition(reached == Set(available.map(\.id)))
                if available.count > StudyQuiz.selection(from: pool, category: category).count { precondition(rounds.count > 1) }
            }
            for field in fields {
                let blanks = pool.filter { $0.fieldID == field.id }
                let restored = StudyQuiz.presentation(field.raw, blanks: blanks, revealed: Set(blanks.map(\.id)))
                precondition(String(restored.characters) == String(StudyQuiz.attributed(field.raw).characters))
            }
        }
        precondition(total >= 400, "Recall target metadata unexpectedly lost")
        print("PASS: \(total) targets; Unicode/Markdown redaction, legacy markers, boundaries, unique answers, all rounds and restoration")
    }
}
