import SwiftUI

/// 「模試」タブ：本番形式の模擬試験(全8回)。ゆとりある一覧デザイン。
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
                            ForEach(store.exams) { exam in
                                let locked = exam.round > freeRounds && !purchases.isPro
                                if locked {
                                    Button { showPaywall = true } label: { examCard(exam, locked: true) }
                                        .buttonStyle(.plain)
                                } else {
                                    NavigationLink {
                                        QuizView(exam: exam, mode: .full)
                                    } label: { examCard(exam, locked: false) }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
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
            .navigationTitle("模試")
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

    private func examCard(_ exam: Exam, locked: Bool = false) -> some View {
        let r = store.latestResult(round: exam.round)
        return HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Theme.line, lineWidth: 1).frame(width: 54, height: 54)
                VStack(spacing: 0) {
                    Text("\(exam.round)").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(Theme.accent2)
                    Text("回").font(.system(size: 9)).foregroundColor(Theme.muted)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("模擬試験 第\(exam.round)回").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.fg)
                HStack(spacing: 14) {
                    label("doc.text", "全\(exam.questions.count)問")
                    label("clock", "40分")
                }
                if locked {
                    Pill(text: "PRO で解放", fg: Theme.accent2, bg: Theme.accent2.opacity(0.16))
                } else if let r = r {
                    Pill(text: "受験済 \(r.percent)点", fg: r.percent >= 60 ? Theme.good : Theme.accent2,
                         bg: (r.percent >= 60 ? Theme.good : Theme.accent2).opacity(0.16))
                } else {
                    Pill(text: "未受験", fg: Color(hex: 0x5AA9FF), bg: Color(hex: 0x5AA9FF).opacity(0.16))
                }
            }
            Spacer(minLength: 4)
            Image(systemName: locked ? "lock.fill" : "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(locked ? Theme.accent2 : Theme.faint)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
    }

    private func label(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11)).foregroundColor(Theme.faint)
            Text(text).font(.system(size: 12)).foregroundColor(Theme.muted)
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
