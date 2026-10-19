import SwiftUI

/// 「成績」タブ：第1回〜第12回の模試を模試タブと同じカードで一覧表示。
/// 受験済カードをタップすると、その回の結果＋間違えた問題を確認できる。
struct ScoreView: View {
    @EnvironmentObject var store: ExamStore
    @EnvironmentObject var purchases: PurchaseStore
    @EnvironmentObject var router: Router
    @State private var showPaywall = false

    /// 無料で解放する回数（第1回まで無料）
    private let freeRounds = 1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    examListSection
                    fieldSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("成績")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: 模試一覧（第1回〜第12回）
    private var examListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHead(title: "模擬試験の成績", trailing: "\(store.examsTaken)/\(store.examTotal) 受験")
            if store.exams.isEmpty {
                emptyCard("chart.bar.doc.horizontal", "問題データを読み込めませんでした",
                          "通信環境を確認して、アプリを開き直してください。")
            } else {
                VStack(spacing: 14) {
                    ForEach(store.exams) { exam in examRow(exam) }
                }
                Text("受験済の回をタップすると、結果と間違えた問題を確認できます。")
                    .font(.system(size: 12)).foregroundColor(Theme.faint).padding(.horizontal, 2)
            }
        }
    }

    @ViewBuilder
    private func examRow(_ exam: Exam) -> some View {
        let locked = exam.round > freeRounds && !purchases.isPro
        let r = store.latestResult(round: exam.round)
        if locked {
            // 未購入でロック中 → 購入画面へ
            Button { showPaywall = true } label: {
                ExamCard(round: exam.round, questionCount: exam.questions.count, status: .locked)
            }
            .buttonStyle(.plain)
        } else if let r = r {
            // 受験済 → 結果＋間違えた問題の詳細へ
            NavigationLink {
                ResultView(exam: exam, result: r)
            } label: {
                ExamCard(round: exam.round, questionCount: exam.questions.count, status: .score(r.percent))
            }
            .buttonStyle(.plain)
        } else {
            // 未受験 → 模試タブへ移動して受験
            Button { router.tab = 2 } label: {
                ExamCard(round: exam.round, questionCount: exam.questions.count, status: .untaken)
            }
            .buttonStyle(.plain)
        }
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

    private func emptyCard(_ icon: String, _ title: String, _ sub: String) -> some View {
        VStack(spacing: 11) {
            Image(systemName: icon).font(.system(size: 40)).foregroundColor(Theme.faint)
            Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(Theme.fg)
            Text(sub).font(.system(size: 12)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 36)
        .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
    }
}
