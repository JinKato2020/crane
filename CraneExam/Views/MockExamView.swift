import SwiftUI

/// 「模試」タブ：模擬試験(全12回)と成績を統合。
/// 各回カードに「試験を始める」「成績を確認する」の2ボタンを置き、受験と復習を1画面で区別する。
/// 無料は第1回のみ。第2回以降は Pro(買い切り)で解放。
struct MockExamView: View {
    @EnvironmentObject var store: ExamStore
    @EnvironmentObject var purchases: PurchaseStore
    @State private var showPaywall = false

    /// 無料で解放する回数(第1回まで無料)
    private let freeRounds = 1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    if store.exams.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 14) {
                            ForEach(store.exams) { exam in examRow(exam) }
                        }
                        fieldSection
                    }
                    Text("全問オリジナル作問。制限時間の目安は各40分です。")
                        .font(.system(size: 12)).foregroundColor(Theme.faint)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("模試・成績")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // 画面上部のイントロ
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MOCK EXAM")
                .font(.system(size: 11, weight: .semibold)).tracking(2)
                .foregroundColor(Theme.accent2)
            Text("模擬試験で力試し")
                .font(.system(size: 24, weight: .heavy)).foregroundColor(Theme.fg)
            HStack(spacing: 18) {
                metric("\(store.exams.count)", "回分")
                metric("40", "問 / 回")
                metric("\(store.examsTaken)", "受験済")
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private func metric(_ v: String, _ unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(v).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(Theme.accent2)
            Text(unit).font(.system(size: 11)).foregroundColor(Theme.muted)
        }
    }

    // MARK: 1回分のカード（情報＋2ボタン）
    @ViewBuilder
    private func examRow(_ exam: Exam) -> some View {
        let locked = exam.round > freeRounds && !purchases.isPro
        let r = store.latestResult(round: exam.round)
        VStack(spacing: 13) {
            infoHeader(exam: exam, locked: locked, result: r)
            HStack(spacing: 10) {
                startButton(exam: exam, locked: locked)
                reviewButton(exam: exam, result: r)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
    }

    private func infoHeader(exam: Exam, locked: Bool, result: ExamResult?) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Theme.line, lineWidth: 1).frame(width: 50, height: 50)
                VStack(spacing: 0) {
                    Text("\(exam.round)").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(Theme.accent2)
                    Text("回").font(.system(size: 9)).foregroundColor(Theme.muted)
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("模擬試験 第\(exam.round)回").font(.system(size: 15.5, weight: .bold)).foregroundColor(Theme.fg)
                HStack(spacing: 12) {
                    metaLabel("doc.text", "全\(exam.questions.count)問")
                    metaLabel("clock", "40分")
                }
                statusPill(locked: locked, result: result)
            }
            Spacer(minLength: 4)
        }
    }

    @ViewBuilder
    private func statusPill(locked: Bool, result: ExamResult?) -> some View {
        if locked {
            Pill(text: "PRO で解放", fg: Theme.accent2, bg: Theme.accent2.opacity(0.16))
        } else if let r = result {
            Pill(text: "受験済 \(r.percent)点",
                 fg: r.percent >= 60 ? Theme.good : Theme.accent2,
                 bg: (r.percent >= 60 ? Theme.good : Theme.accent2).opacity(0.16))
        } else {
            Pill(text: "未受験", fg: Color(hex: 0x5AA9FF), bg: Color(hex: 0x5AA9FF).opacity(0.16))
        }
    }

    private func metaLabel(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11)).foregroundColor(Theme.faint)
            Text(text).font(.system(size: 12)).foregroundColor(Theme.muted)
        }
    }

    // 試験を始める（ロック中は購入画面へ）
    @ViewBuilder
    private func startButton(exam: Exam, locked: Bool) -> some View {
        if locked {
            Button { showPaywall = true } label: { primaryLabel("試験を始める", icon: "lock.fill") }
                .buttonStyle(.plain)
        } else {
            NavigationLink { QuizView(exam: exam, mode: .full) } label: { primaryLabel("試験を始める", icon: "play.fill") }
                .buttonStyle(.plain)
        }
    }

    // 成績を確認する（未受験は押せない見た目に）
    @ViewBuilder
    private func reviewButton(exam: Exam, result: ExamResult?) -> some View {
        if let r = result {
            NavigationLink { ResultView(exam: exam, result: r) } label: { secondaryLabel("成績を確認する", icon: "chart.bar.fill", enabled: true) }
                .buttonStyle(.plain)
        } else {
            secondaryLabel("成績を確認する", icon: "chart.bar.fill", enabled: false)
        }
    }

    private func primaryLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12, weight: .bold))
            Text(title).font(.system(size: 13.5, weight: .heavy))
        }
        .frame(maxWidth: .infinity, minHeight: 42)
        .foregroundColor(Color(hex: 0x241703))
        .background(Theme.gold)
        .clipShape(RoundedRectangle(cornerRadius: 11))
    }

    private func secondaryLabel(_ title: String, icon: String, enabled: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12, weight: .bold))
            Text(title).font(.system(size: 13.5, weight: .heavy))
        }
        .frame(maxWidth: .infinity, minHeight: 42)
        .foregroundColor(Theme.accent2)
        .background(Theme.accent2.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 11))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.accent2.opacity(0.35), lineWidth: 1))
        .opacity(enabled ? 1.0 : 0.4)
    }

    // MARK: 分野別の到達度（全結果の合算）
    private var fieldSection: some View {
        let acc = store.subjectAccuracy()
        return VStack(alignment: .leading, spacing: 12) {
            SectionHead(title: "分野別の到達度", trailing: "全結果の合算")
            Card {
                VStack(spacing: 4) {
                    ForEach(acc, id: \.name) { item in
                        BarRow(name: subjectShort(item.name), pct: item.pct)
                    }
                }
            }
            if store.results.isEmpty {
                Text("模擬試験を受けると、分野別の正答率がここに反映されます。")
                    .font(.system(size: 12)).foregroundColor(Theme.faint).padding(.horizontal, 2)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass").font(.system(size: 42)).foregroundColor(Theme.faint)
            Text("問題データを読み込めませんでした。")
                .font(.system(size: 13)).foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60)
    }
}
