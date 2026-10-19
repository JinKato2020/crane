import SwiftUI

/// 「模試」タブ：本番形式の模擬試験(全12回)。ゆとりある一覧デザイン。
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
                                let r = store.latestResult(round: exam.round)
                                let status: ExamCard.Status = r.map { .score($0.percent) } ?? .untaken
                                if locked {
                                    Button { showPaywall = true } label: {
                                        ExamCard(round: exam.round, questionCount: exam.questions.count, status: .locked)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    NavigationLink {
                                        QuizView(exam: exam, mode: .full)
                                    } label: {
                                        ExamCard(round: exam.round, questionCount: exam.questions.count, status: status)
                                    }
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

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass").font(.system(size: 42)).foregroundColor(Theme.faint)
            Text("問題データを読み込めませんでした。")
                .font(.system(size: 13)).foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60)
    }
}
