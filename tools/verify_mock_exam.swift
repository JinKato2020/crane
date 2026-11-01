import Foundation

/// 実際のモデルを使い、制限時間の境界・制限なし・未回答の採点を検証する。
@main
struct MockExamVerification {
    static func main() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1])
        let exams = try JSONDecoder().decode([Exam].self,
            from: Data(contentsOf: root.appendingPathComponent("exams.json")))
        let start = Date(timeIntervalSince1970: 1_000_000)
        let limited = MockExamClock(limited: true, startedAt: start)
        let unlimited = MockExamClock(limited: false, startedAt: start)
        precondition(CraneExamFormat.durationSeconds == 9000)
        precondition(limited.remainingSeconds(at: start) == 9000)
        precondition(!limited.hasExpired(at: start.addingTimeInterval(8999)))
        precondition(limited.remainingSeconds(at: start.addingTimeInterval(8999)) == 1)
        precondition(limited.hasExpired(at: start.addingTimeInterval(9000)))
        precondition(limited.remainingSeconds(at: start.addingTimeInterval(9000)) == 0)
        // バックグラウンド等で通知が飛ばされても、時刻差で期限超過を判定する。
        precondition(limited.hasExpired(at: start.addingTimeInterval(10800)))
        precondition(limited.elapsedSeconds(at: start.addingTimeInterval(10800)) == 9000)
        precondition(!unlimited.hasExpired(at: start.addingTimeInterval(10800)))
        precondition(unlimited.elapsedSeconds(at: start.addingTimeInterval(10800)) == 10800)
        precondition(limited.elapsedSeconds(at: start.addingTimeInterval(-1)) == 0)

        for exam in exams {
            precondition(exam.questions.map(\.numberForDisplay) == Array(1...40))
            precondition([0,10,20,30].map { exam.questions[$0].subject } == ["クレーンに関する知識","関係法令","原動機・電気","力学"])
            for question in exam.questions {
                if let headers = question.choiceHeaders, let rows = question.choiceRows {
                    precondition(rows.count == 5 && rows.allSatisfy { $0.count == headers.count })
                }
            }
            let empty = MockExamScore(exam: exam, answers: [:], elapsed: 9000, date: start)
            precondition(empty.result.correct == 0 && empty.result.total == 40)
            precondition(empty.wrongRefs.count == 40)
            precondition(empty.result.perSubject.values.allSatisfy { $0 == [0, 10] })
            let correct = Dictionary(uniqueKeysWithValues: exam.questions.map { ($0.no, $0.answer - 1) })
            let full = MockExamScore(exam: exam, answers: correct, elapsed: 8999, date: start)
            precondition(full.result.correct == 40 && full.wrongRefs.isEmpty)
            precondition(full.result.examScore == 100 && full.result.isPassing)
            precondition(full.result.perSubject.values.allSatisfy { $0 == [10, 10] })
            let first = exam.questions[0], second = exam.questions[1]
            var partial = [first.no: first.answer - 1, second.no: second.answer % second.choices.count]
            // 同じ問題のキーを再設定しても、問題数・得点が増えない。
            partial[first.no] = first.answer - 1
            let timedOut = MockExamScore(exam: exam, answers: partial, elapsed: 9000, date: start)
            precondition(timedOut.result.correct == 1 && timedOut.result.total == 40)
            precondition(timedOut.wrongRefs.count == 39)
            precondition(!timedOut.wrongRefs.contains { $0.no == first.no })
            precondition(timedOut.result.perSubject.values.reduce(0) { $0 + $1[1] } == 40)
            precondition(timedOut.result.elapsed == 9000)
            func profile(_ counts: [String: Int]) -> ExamResult {
                var remaining = counts
                var answers: [Int: Int] = [:]
                for question in exam.questions where remaining[question.subject, default: 0] > 0 {
                    answers[question.no] = question.answer - 1
                    remaining[question.subject, default: 0] -= 1
                }
                return MockExamScore(exam: exam, answers: answers, elapsed: 100, date: start).result
            }
            let rawSixty = profile(["クレーンに関する知識":4,"原動機・電気":4,"関係法令":8,"力学":8])
            precondition(rawSixty.percent == 60 && rawSixty.examScore == 56 && !rawSixty.isPassing)
            let weightedPass = profile(["クレーンに関する知識":8,"原動機・電気":7,"関係法令":4,"力学":4])
            precondition(weightedPass.correct == 23 && weightedPass.examScore == 61 && weightedPass.isPassing)
            let belowMinimum = profile(["クレーンに関する知識":10,"原動機・電気":10,"関係法令":0,"力学":4])
            precondition(belowMinimum.examScore == 68 && !belowMinimum.isPassing)
            let exactlySixty = profile(["クレーンに関する知識":6,"原動機・電気":6,"関係法令":6,"力学":6])
            precondition(exactlySixty.examScore == 60 && exactlySixty.isPassing)
        }
        print("Mock exam verification passed: timer boundaries, unlimited mode, scoring across \(exams.count) exams")
    }
}
