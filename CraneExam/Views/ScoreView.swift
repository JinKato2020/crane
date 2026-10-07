import SwiftUI

/// 「成績」タブ：成績履歴・分野別の到達度・マイノートを1画面に統合。
struct ScoreView: View {
    @EnvironmentObject var store: ExamStore

    private var sorted: [ExamResult] { store.results.sorted { $0.date > $1.date } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    scoreSection
                    fieldSection
                    noteSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("成績")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: 成績履歴
    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if sorted.isEmpty {
                SectionHead(title: "成績")
                emptyCard("chart.bar.doc.horizontal", "まだ受験記録がありません",
                          "「模試」タブで模擬試験を受けると、ここに結果が表示されます。")
            } else {
                if let latest = sorted.first, let ex = store.exam(latest.round) {
                    SectionHead(title: "最新の結果")
                    NavigationLink { ResultView(exam: ex, result: latest) } label: { latestCard(latest) }
                        .buttonStyle(.plain)
                }
                SectionHead(title: "受験履歴")
                VStack(spacing: 12) {
                    ForEach(sorted) { r in
                        if let ex = store.exam(r.round) {
                            NavigationLink { ResultView(exam: ex, result: r) } label: { row(r) }
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: 分野別の到達度
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
            if sorted.isEmpty {
                Text("模擬試験を受けると、分野別の正答率がここに反映されます。")
                    .font(.system(size: 12)).foregroundColor(Theme.faint).padding(.horizontal, 2)
            }
        }
    }

    // MARK: マイノート
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHead(title: "マイノート")
            NoteView()
        }
    }

    // MARK: パーツ
    private func latestCard(_ r: ExamResult) -> some View {
        Card(padding: 18) {
            HStack(spacing: 18) {
                Ring(progress: Double(r.percent) / 100, size: 90, line: 10,
                     label: "\(r.percent)", sub: "点")
                VStack(alignment: .leading, spacing: 6) {
                    Text("第\(r.round)回 模擬試験").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.fg)
                    Text("正答 \(r.correct)/\(r.total)問").font(.system(size: 12.5)).foregroundColor(Theme.muted)
                    Text(r.percent >= 60 ? "合格ライン超え" : "もう一歩")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(r.percent >= 60 ? Theme.good : Theme.accent2)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(Theme.faint)
            }
        }
    }

    private func row(_ r: ExamResult) -> some View {
        HStack(spacing: 16) {
            Text("\(r.percent)")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundColor(r.percent >= 60 ? Theme.good : Theme.accent2)
                .frame(width: 54, height: 54)
                .background(Theme.raise).clipShape(RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text("第\(r.round)回 模擬試験").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.fg)
                Text("\(dateStr(r.date)) · 正答 \(r.correct)/\(r.total)").font(.system(size: 12)).foregroundColor(Theme.muted)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundColor(Theme.faint)
        }
        .padding(16)
        .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
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

    private func dateStr(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "ja_JP"); f.dateFormat = "M/d HH:mm"
        return f.string(from: d)
    }
}
