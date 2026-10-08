import SwiftUI

/// 問題データの読み込みと学習状態（結果・ブックマーク・弱点）の保存
final class ExamStore: ObservableObject {
    @Published private(set) var exams: [Exam] = []
    @Published private(set) var textbook: Textbook? = nil
    /// 図アセット名 → ラベル/凡例/キャプション(教材imgブロックから集約)
    private(set) var figureInfo: [String: TBFigureInfo] = [:]
    @Published private(set) var results: [ExamResult] = []
    @Published private(set) var bookmarks: Set<String> = []
    @Published private(set) var wrongs: [WrongRef] = []

    private let kResults = "cr_results"
    private let kBookmarks = "cr_bookmarks"
    private let kWrongs = "cr_wrongs"

    init() {
        loadExams()
        loadTextbook()
        load()
        // OTA: 裏で棚(R2)の最新コンテンツを取り込み、更新があれば同じ起動中に反映する。
        // 通信断などで失敗しても内蔵データで動く(壊れない)。反映は次回起動 or ここでの再読込。
        Task { [weak self] in
            let updated = await ContentOTA.sync()
            if updated > 0 {
                await MainActor.run {
                    self?.loadExams()
                    self?.loadTextbook()
                }
            }
        }
    }

    private func loadTextbook() {
        guard let data = ContentOTA.contentData(key: "content/textbook.json", bundledResource: "textbook"),
              let decoded = try? JSONDecoder().decode(Textbook.self, from: data) else {
            textbook = nil; return
        }
        textbook = decoded
        buildFigureInfo()
    }

    /// 教材の全imgブロックを走査し、アセット名→ラベル/凡例/キャプションの表を作る
    private func buildFigureInfo() {
        var map: [String: TBFigureInfo] = [:]
        for ch in textbook?.chapters ?? [] {
            for sec in ch.sections {
                for b in sec.blocks where b.type == "img" {
                    guard let a = b.asset, map[a] == nil else { continue }
                    map[a] = TBFigureInfo(labels: b.labels ?? [], legend: b.legend ?? [], caption: b.caption)
                }
            }
        }
        figureInfo = map
    }

    private func loadExams() {
        guard let data = ContentOTA.contentData(key: "content/exams.json", bundledResource: "exams"),
              let decoded = try? JSONDecoder().decode([Exam].self, from: data) else {
            exams = []; return
        }
        exams = decoded.sorted { $0.round < $1.round }
    }

    private func load() {
        let d = UserDefaults.standard
        if let r = d.data(forKey: kResults),
           let v = try? JSONDecoder().decode([ExamResult].self, from: r) { results = v }
        if let b = d.stringArray(forKey: kBookmarks) { bookmarks = Set(b) }
        if let w = d.data(forKey: kWrongs),
           let v = try? JSONDecoder().decode([WrongRef].self, from: w) { wrongs = v }
    }

    private func save() {
        let d = UserDefaults.standard
        d.set(try? JSONEncoder().encode(results), forKey: kResults)
        d.set(Array(bookmarks), forKey: kBookmarks)
        d.set(try? JSONEncoder().encode(wrongs), forKey: kWrongs)
    }

    func exam(_ round: Int) -> Exam? { exams.first { $0.round == round } }

    func latestResult(round: Int) -> ExamResult? {
        results.filter { $0.round == round }.max { $0.date < $1.date }
    }

    func saveResult(_ r: ExamResult, wrongRefs: [WrongRef]) {
        results.append(r)
        for w in wrongRefs where !wrongs.contains(w) { wrongs.append(w) }
        save()
    }

    func toggleBookmark(_ id: String) {
        if bookmarks.contains(id) { bookmarks.remove(id) } else { bookmarks.insert(id) }
        save()
    }
    func isBookmarked(_ id: String) -> Bool { bookmarks.contains(id) }

    func removeWrong(_ w: WrongRef) { wrongs.removeAll { $0 == w }; save() }

    // 統計
    var totalAnswered: Int { results.reduce(0) { $0 + $1.total } }
    var totalCorrect: Int { results.reduce(0) { $0 + $1.correct } }
    var accuracy: Int { totalAnswered == 0 ? 0 : Int((Double(totalCorrect) / Double(totalAnswered) * 100).rounded()) }
    var examsTaken: Int { Set(results.map { $0.round }).count }
    var progress: Int { Int((Double(examsTaken) / 8.0 * 100).rounded()) }

    func subjectAccuracy() -> [(name: String, pct: Int)] {
        var agg: [String: [Int]] = [:]
        for r in results {
            for (s, v) in r.perSubject {
                var cur = agg[s] ?? [0, 0]; cur[0] += v[0]; cur[1] += v[1]; agg[s] = cur
            }
        }
        return SUBJECTS.map { s in
            let v = agg[s] ?? [0, 0]
            return (s, v[1] == 0 ? 0 : Int((Double(v[0]) / Double(v[1]) * 100).rounded()))
        }
    }

    func bookmarkedQuestions() -> [(Exam, Question)] {
        var out: [(Exam, Question)] = []
        for e in exams {
            for q in e.questions where bookmarks.contains("\(e.round)-\(q.no)") {
                out.append((e, q))
            }
        }
        return out
    }

    func question(_ w: WrongRef) -> Question? {
        exam(w.round)?.questions.first { $0.no == w.no }
    }
}
