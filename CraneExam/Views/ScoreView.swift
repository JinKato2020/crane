import SwiftUI

struct ScoreView: View {
    @EnvironmentObject var store: ExamStore

    private var sorted: [ExamResult] { store.results.sorted { $0.date > $1.date } }

    var body: some View {
        NavigationStack {
            ScrollView {
                if sorted.isEmpty {
                    emptyState.padding(.top, 60)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        if let latest = sorted.first, let ex = store.exam(latest.round) {
                            SectionHead(title: "最新の結果")
                            NavigationLink { ResultView(exam: ex, result: latest) } label: { latestCard(latest) }
                                .buttonStyle(.plain)
                        }
                        SectionHead(title: "受験履歴")
                        ForEach(sorted) { r in
                            if let ex = store.exam(r.round) {
                                NavigationLink { ResultView(exam: ex, result: r) } label: { row(r) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("成績")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func latestCard(_ r: ExamResult) -> some View {
        Card(padding: 16) {
            HStack(spacing: 16) {
                Ring(progress: Double(r.percent) / 100, size: 86, line: 10,
                     label: "\(r.percent)", sub: "点")
                VStack(alignment: .leading, spacing: 5) {
                    Text("第\(r.round)回 模擬試験").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.fg)
                    Text("正答 \(r.correct)/\(r.total)問").font(.system(size: 12)).foregroundColor(Theme.muted)
                    Text(r.percent >= 60 ? "合格ライン超え" : "もう一歩")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(r.percent >= 60 ? Theme.good : Theme.accent2)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(Theme.faint)
            }
        }
    }

    private func row(_ r: ExamResult) -> some View {
        HStack(spacing: 13) {
            Text("\(r.percent)")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(r.percent >= 60 ? Theme.good : Theme.accent2)
                .frame(width: 46, height: 46)
                .background(Theme.raise).clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text("第\(r.round)回 模擬試験").font(.system(size: 14, weight: .bold)).foregroundColor(Theme.fg)
                Text("\(dateStr(r.date)) · 正答 \(r.correct)/\(r.total)").font(.system(size: 11)).foregroundColor(Theme.muted)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.faint)
        }
        .padding(13)
        .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 44)).foregroundColor(Theme.faint)
            Text("まだ受験記録がありません").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.fg)
            Text("「学科」タブの模擬試験を受けると、\nここに結果と分野別の正答率が表示されます。")
                .font(.system(size: 12)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }

    private func dateStr(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "ja_JP"); f.dateFormat = "M/d HH:mm"
        return f.string(from: d)
    }
}
