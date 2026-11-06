import SwiftUI

enum QuizMode { case full }

struct QuizView: View {
    let exam: Exam
    var mode: QuizMode = .full
    var timeLimitEnabled = true

    @EnvironmentObject var store: ExamStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var index = 0
    @State private var selected: Int? = nil     // 0始まり
    @State private var answered = false
    @State private var submittedAnswers: [Int: Int] = [:]
    @State private var clock: MockExamClock?
    @State private var showTimeExpiredAlert = false
    @State private var elapsed = 0
    @State private var finished = false
    @State private var result: ExamResult? = nil
    @State private var selectedRef: TextRef?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var q: Question { exam.questions[index] }
    private var count: Int { exam.questions.count }
    private var bmId: String { "\(exam.round)-\(q.no)" }

    var body: some View {
        Group {
            if finished, let r = result {
                ResultView(exam: exam, result: r)
            } else {
                quiz
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            store.rememberStudy(StudyPlace(kind: .exam, title: "模擬試験 第\(exam.round)回", examRound: exam.round))
            if clock == nil { clock = MockExamClock(limited: timeLimitEnabled, startedAt: Date()) }
            updateClock()
        }
        .onReceive(timer) { date in updateClock(at: date) }
        .onChange(of: scenePhase) { phase in
            if phase == .active { updateClock() }
        }
        .alert("制限時間になりました", isPresented: $showTimeExpiredAlert) {
            Button("結果を確認", role: .cancel) { }
        } message: {
            Text("150分が経過したため終了しました。選択済みの解答を採点し、未回答は不正解として記録しました。")
        }
        .trackStudyCompletion(kind: .exam)
    }

    private var quiz: some View {
        VStack(spacing: 0) {
            // 上部
            VStack(spacing: 9) {
                HStack {
                    Button { dismiss() } label: {
                        Label("中断", systemImage: "chevron.left").font(.system(size: 13, weight: .bold))
                    }.foregroundColor(Theme.muted)
                    Spacer()
                    Text("第\(exam.round)回 模擬試験").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted)
                    Spacer()
                    HStack(spacing: 5) {
                        Image(systemName: "clock")
                        Text(timeLimitEnabled
                             ? "残り \(timeString(max(0, CraneExamFormat.durationSeconds - elapsed)))"
                             : "経過 \(timeString(elapsed))").monospacedDigit()
                    }.font(.system(size: 13, weight: .semibold))
                        .foregroundColor(timeLimitEnabled && CraneExamFormat.durationSeconds - elapsed <= 300 ? Theme.warn : Theme.accent2)
                }
                ProgressView(value: Double(index + 1), total: Double(count))
                    .tint(Theme.accent)
                Text(timeLimitEnabled ? "\(CraneExamFormat.durationMinutes)分で自動終了・採点" : "時間制限なし")
                    .font(.system(size: 11)).foregroundColor(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 10)
            .background(Theme.bg)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 9) {
                        Text(q.subject)
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Theme.raise).foregroundColor(Theme.accent2).clipShape(Capsule())
                        Text("第\(index + 1)問 / \(count)").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted)
                        Spacer()
                        Button { store.toggleBookmark(bmId) } label: {
                            Image(systemName: store.isBookmarked(bmId) ? "bookmark.fill" : "bookmark")
                                .foregroundColor(store.isBookmarked(bmId) ? Theme.accent : Theme.muted)
                        }
                    }

                    Text(q.text)
                        .font(.system(size: 16, weight: .bold)).foregroundColor(Theme.fg)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(5)

                    if let fig = q.figImg, !fig.isEmpty {
                        FigureImageView(assetName: fig, thumbMaxHeight: 230)
                    } else if let fig = q.figure, !fig.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(fig)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Theme.muted)
                                .padding(12)
                        }
                        .background(Theme.card2).clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    if let headers = q.choiceHeaders {
                        HStack(spacing: 12) {
                            Color.clear.frame(width: 26, height: 1)
                            ForEach(headers.indices, id: \.self) { column in
                                Text(headers[column])
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.muted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal, 13)
                    }
                    ForEach(Array(q.choices.enumerated()), id: \.offset) { i, c in
                        choiceButton(i, c)
                    }

                    if answered && !timeLimitEnabled {
                        explanationBox
                    }
                }
                .padding(16)
            }

            // 下部アクション
            HStack(spacing: 10) {
                if index > 0 {
                    Button { goPrev() } label: {
                        Image(systemName: "chevron.left").frame(width: 52, height: 50)
                            .background(Theme.card).foregroundColor(Theme.muted)
                            .clipShape(RoundedRectangle(cornerRadius: 13))
                            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.line, lineWidth: 1))
                    }
                }
                Button { primaryAction() } label: {
                    Text(primaryLabel)
                        .font(.system(size: 15, weight: .heavy)).foregroundColor(Color(hex: 0x241703))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Theme.gold).clipShape(RoundedRectangle(cornerRadius: 13))
                }
                .disabled(!timeLimitEnabled && selected == nil && !answered)
                .opacity((!timeLimitEnabled && selected == nil && !answered) ? 0.5 : 1)
            }
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 10)
            .background(Theme.bg)
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(item: $selectedRef) { ref in
            TextbookRefSheet(ref: ref).environmentObject(store)
        }
    }

    private func choiceButton(_ i: Int, _ text: String) -> some View {
        let state = choiceState(i)
        return Button {
            updateClock()
            guard !finished else { return }
            if !answered || timeLimitEnabled { selected = i }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Text("\(i + 1)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .frame(width: 26, height: 26)
                    .background(state.numBg).foregroundColor(state.numFg)
                    .clipShape(Circle())
                if let rows = q.choiceRows, rows.indices.contains(i) {
                    ForEach(rows[i].indices, id: \.self) { column in
                        Text(rows[i][column])
                            .font(.system(size: 13.5)).foregroundColor(Theme.fg)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    Text(text)
                        .font(.system(size: 13.5)).foregroundColor(Theme.fg)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(3)
                }
            }
            .padding(13)
            .background(state.bg)
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(state.border, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private struct CState { var bg: Color; var border: Color; var numBg: Color; var numFg: Color }
    private func choiceState(_ i: Int) -> CState {
        let correctIdx = q.answer - 1
        if answered && !timeLimitEnabled {
            if i == correctIdx { return CState(bg: Theme.good.opacity(0.14), border: Theme.good, numBg: Theme.good, numFg: Color(hex: 0x06230F)) }
            if i == selected { return CState(bg: Theme.warn.opacity(0.14), border: Theme.warn, numBg: Theme.warn, numFg: Color(hex: 0x2A0B07)) }
            return CState(bg: Theme.card, border: Theme.line, numBg: Theme.raise, numFg: Theme.muted)
        }
        if i == selected { return CState(bg: Theme.selectedAnswer, border: Theme.accent, numBg: Theme.accent, numFg: Color(hex: 0x241703)) }
        return CState(bg: Theme.card, border: Theme.line, numBg: Theme.raise, numFg: Theme.muted)
    }

    private var explanationBox: some View {
        let ok = selected == q.answer - 1
        return VStack(alignment: .leading, spacing: 6) {
            Text(ok ? "正解!" : "不正解")
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(ok ? Theme.good : Theme.warn)
            Text("【解説】\(q.explanation)")
                .font(.system(size: 12.5)).foregroundColor(Theme.muted).lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            if let fe = q.figImgExp, !fe.isEmpty {
                FigureImageView(assetName: fe, thumbMaxHeight: 230)
            }
            ForEach(q.textbookReferences) { ref in
                TextRefButton(ref: ref) { selectedRef = ref }.padding(.top, 2)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card2)
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 11))
        .overlay(alignment: .leading) { Rectangle().fill(Theme.accent).frame(width: 3) }
    }

    private var primaryLabel: String {
        if timeLimitEnabled { return index == count - 1 ? "終了して採点" : (selected == nil ? "未回答で次へ" : "次の問題へ") }
        if !answered { return "解答する" }
        return index == count - 1 ? "結果を見る" : "次の問題へ"
    }

    private func primaryAction() {
        updateClock()
        guard !finished else { return }
        if timeLimitEnabled {
            submitCurrentAnswer()
            if index == count - 1 { finish() }
            else { index += 1; restoreAnswer() }
            return
        }
        if !answered {
            submitCurrentAnswer()
        } else {
            if index == count - 1 { finish() }
            else { index += 1; restoreAnswer() }
        }
    }

    private func submitCurrentAnswer() {
        guard let sel = selected else { return }
        let isFirstSubmission = submittedAnswers[q.no] == nil
        submittedAnswers[q.no] = sel
        answered = true
        if isFirstSubmission { store.recordAnswers(1) }
    }

    private func restoreAnswer() {
        selected = submittedAnswers[q.no]
        answered = selected != nil
    }

    private func goPrev() {
        updateClock()
        guard !finished else { return }
        if timeLimitEnabled { submitCurrentAnswer() }
        if index > 0 { index -= 1; restoreAnswer() }
    }

    private func updateClock(at date: Date = Date()) {
        guard !finished, let clock else { return }
        elapsed = clock.elapsedSeconds(at: date)
        if clock.hasExpired(at: date) { finish(timedOut: true) }
    }

    private func finish(timedOut: Bool = false) {
        guard !finished else { return }
        // 時間切れ直前に選択していた解答も採点対象にする。
        if timeLimitEnabled || !answered { submitCurrentAnswer() }
        let score = MockExamScore(exam: exam, answers: submittedAnswers, elapsed: elapsed)
        store.saveResult(score.result, wrongRefs: score.wrongRefs)
        result = score.result
        selectedRef = nil
        showTimeExpiredAlert = timedOut
        finished = true
    }

    private func timeString(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}
