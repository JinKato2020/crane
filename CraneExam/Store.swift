import SwiftUI

/// 問題データの読み込みと学習状態（結果・ブックマーク・弱点）の保存
final class ExamStore: ObservableObject {
    @Published private(set) var exams: [Exam] = []
    @Published private(set) var textbook: Textbook? = nil
    @Published private(set) var isSyncingContent = false
    @Published private(set) var contentSyncMessage = "起動時に更新を確認します"
    @Published private(set) var contentSyncCompleted = 0
    @Published private(set) var contentSyncTotal = 0
    @Published private(set) var contentRevision = 0
    private var lastContentSyncAt: Date?
    /// 図アセット名 → ラベル/凡例/キャプション(教材imgブロックから集約)
    private(set) var figureInfo: [String: TBFigureInfo] = [:]
    @Published private(set) var results: [ExamResult] = []
    @Published private(set) var bookmarks: Set<String> = []
    @Published private(set) var wrongs: [WrongRef] = []
    @Published private(set) var favTerms: Set<String> = []   // お気に入り用語(TBTerm.id=用語名で保持)
    /// 評価依頼: 完了回数のうちマイルストーン(1回目/7回目)で一度だけ依頼済みにする
    @Published private(set) var reviewAsked: Set<Int> = []
    /// trueの間、ビューがApp Store評価依頼(requestReview)を出す。出したらfalseへ戻す(非永続)
    @Published var pendingReview = false
    private let reviewMilestones: Set<Int> = [1, 7]
    /// 学習の継続カード用: 日別の解答数。キー="yyyy-MM-dd" → その日に解いた問題数
    @Published private(set) var dailyAnswers: [String: Int] = [:]

    private let kResults = "cr_results"
    private let kBookmarks = "cr_bookmarks"
    private let kWrongs = "cr_wrongs"
    private let kFavTerms = "cr_fav_terms"
    private let kReviewAsked = "cr_review_asked"
    private let kDaily = "cr_daily_answers"

    init() {
        loadExams()
        loadTextbook()
        load()
        // OTA: 裏で棚(R2)の最新コンテンツを取り込み、更新があれば同じ起動中に反映する。
        // 通信断などで失敗しても内蔵データで動く(壊れない)。反映は次回起動 or ここでの再読込。
        Task { [weak self] in
            await self?.syncContent()
        }
    }

    @MainActor
    func syncContent(manual: Bool = false) async {
        guard !isSyncingContent else { return }
        if !manual, let lastContentSyncAt, Date().timeIntervalSince(lastContentSyncAt) < 60 { return }
        isSyncingContent = true
        contentSyncCompleted = 0
        contentSyncTotal = 0
        contentSyncMessage = "更新を確認しています…"
        defer { isSyncingContent = false }
        let result = await ContentOTA.sync { [weak self] completed, total in
            self?.contentSyncCompleted = completed
            self?.contentSyncTotal = total
            if total > 0 { self?.contentSyncMessage = "教材・画像を取得中 \(completed) / \(total)" }
        }
        if result.updated > 0 {
            loadExams()
            loadTextbook()
            contentRevision += 1
        }
        if let message = result.message {
            contentSyncMessage = message
        } else {
            lastContentSyncAt = Date()
            contentSyncMessage = result.updated > 0 ? "教材・画像を更新しました" : "最新の教材・画像です"
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
        if let f = d.stringArray(forKey: kFavTerms) { favTerms = Set(f) }
        if let a = d.array(forKey: kReviewAsked) as? [Int] { reviewAsked = Set(a) }
        if let m = d.dictionary(forKey: kDaily) as? [String: Int] { dailyAnswers = m }
    }

    private func save() {
        let d = UserDefaults.standard
        d.set(try? JSONEncoder().encode(results), forKey: kResults)
        d.set(Array(bookmarks), forKey: kBookmarks)
        d.set(try? JSONEncoder().encode(wrongs), forKey: kWrongs)
        d.set(Array(favTerms), forKey: kFavTerms)
        d.set(Array(reviewAsked), forKey: kReviewAsked)
        d.set(dailyAnswers, forKey: kDaily)
    }

    func exam(_ round: Int) -> Exam? { exams.first { $0.round == round } }

    func latestResult(round: Int) -> ExamResult? {
        results.filter { $0.round == round }.max { $0.date < $1.date }
    }

    func saveResult(_ r: ExamResult, wrongRefs: [WrongRef]) {
        results.append(r)
        for w in wrongRefs where !wrongs.contains(w) { wrongs.append(w) }
        // 完了回数が1回目/7回目に達し、まだ依頼していなければ評価依頼を予約(各一度だけ)
        let count = results.count
        if reviewMilestones.contains(count), !reviewAsked.contains(count) {
            reviewAsked.insert(count)
            pendingReview = true
        }
        save()
    }

    // MARK: - 学習の継続（日別の解答数）
    private func dayKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
    /// 今日の解答数に n を加算（模試で問題に答えるたびに呼ぶ）。
    func recordAnswers(_ n: Int) {
        guard n > 0 else { return }
        dailyAnswers[dayKey(Date()), default: 0] += n
        save()
    }
    /// 直近 days 日（今日を含む）の (日付, 解答数)。古い順。
    func recentDaily(_ days: Int) -> [(date: Date, count: Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<days).reversed().map { off in
            let d = cal.date(byAdding: .day, value: -off, to: today) ?? today
            return (date: d, count: dailyAnswers[dayKey(d)] ?? 0)
        }
    }
    /// 今日からさかのぼって連続して学習した日数。
    var studyStreak: Int {
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        var streak = 0
        while (dailyAnswers[dayKey(day)] ?? 0) > 0 {
            streak += 1
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return streak
    }

    func toggleBookmark(_ id: String) {
        if bookmarks.contains(id) { bookmarks.remove(id) } else { bookmarks.insert(id) }
        save()
    }
    func isBookmarked(_ id: String) -> Bool { bookmarks.contains(id) }

    // お気に入り用語（用語集のハート）
    func toggleFavTerm(_ id: String) {
        if favTerms.contains(id) { favTerms.remove(id) } else { favTerms.insert(id) }
        save()
    }
    func isFavTerm(_ id: String) -> Bool { favTerms.contains(id) }

    /// お気に入り登録された用語を、章の並び順で返す（同名用語は最初の1件）。
    func favoriteTerms() -> [(chapter: TBChapter, term: TBTerm)] {
        var seen: Set<String> = []
        var out: [(chapter: TBChapter, term: TBTerm)] = []
        for ch in textbook?.chapters ?? [] {
            for t in ch.glossary ?? [] where favTerms.contains(t.id) && !seen.contains(t.id) {
                seen.insert(t.id); out.append((chapter: ch, term: t))
            }
        }
        return out
    }

    func removeWrong(_ w: WrongRef) { wrongs.removeAll { $0 == w }; save() }

    // 統計
    var totalAnswered: Int { results.reduce(0) { $0 + $1.total } }
    var totalCorrect: Int { results.reduce(0) { $0 + $1.correct } }
    var accuracy: Int { totalAnswered == 0 ? 0 : Int((Double(totalCorrect) / Double(totalAnswered) * 100).rounded()) }
    var examsTaken: Int { Set(results.map { $0.round }).count }
    /// 収録されている模試の総数（1回分＝40問、現在12回）。分母に使う。
    var examTotal: Int { exams.count }
    var progress: Int { examTotal == 0 ? 0 : Int((Double(examsTaken) / Double(examTotal) * 100).rounded()) }

    /// 指定回で「間違えた問題」を問題番号順に返す（成績の復習用）
    func wrongQuestions(round: Int) -> [Question] {
        guard let ex = exam(round) else { return [] }
        let nos = Set(wrongs.filter { $0.round == round }.map { $0.no })
        return ex.questions.filter { nos.contains($0.no) }
    }

    /// 分野別の正答率。asOf を渡すと「その日時までに受けた模試」だけで計算する（過去時点の実力＝成長比較用）。既定(nil)は全期間＝現在。
    func subjectAccuracy(asOf date: Date? = nil) -> [(name: String, pct: Int)] {
        var agg: [String: [Int]] = [:]
        for r in results where (date == nil || r.date <= date!) {
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
