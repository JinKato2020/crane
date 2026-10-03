import SwiftUI

struct ResultView: View {
    let exam: Exam
    let result: ExamResult

    @Environment(\.dismiss) private var dismiss

    private var pass: Bool { result.percent >= 60 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                hero
                stats
                SectionHead(title: "分野別の正答率")
                Card {
                    VStack(spacing: 2) {
                        ForEach(SUBJECTS, id: \.self) { s in
                            let v = result.perSubject[s] ?? [0, 0]
                            let pct = v[1] == 0 ? 0 : Int((Double(v[0]) / Double(v[1]) * 100).rounded())
                            BarRow(name: subjectShort(s), pct: pct)
                        }
                    }
                }
                weakSection
                Button { dismiss() } label: {
                    Text("完了").font(.system(size: 15, weight: .heavy)).foregroundColor(Color(hex: 0x241703))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Theme.gold).clipShape(RoundedRectangle(cornerRadius: 13))
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("模擬試験 結果")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        Card(padding: 18) {
            VStack(spacing: 8) {
                Text("第\(exam.round)回 模擬試験 · \(dateStr(result.date))")
                    .font(.system(size: 12)).foregroundColor(Theme.muted)
                Ring(progress: Double(result.percent) / 100, size: 128, line: 12,
                     label: "\(result.correct)", sub: "点 / \(result.total)")
                Text("総合評価").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted)
                Text(pass ? "合格ライン(60%)を超えました。順調です！" : "合格ラインまであと少し。弱点を復習しましょう。")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(pass ? Theme.good : Theme.accent2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var stats: some View {
        HStack(spacing: 10) {
            statCell("\(result.correct)/\(result.total)", "正答数")
            statCell(timeString(result.elapsed), "所要時間")
            statCell("\(result.percent)%", "得点率", Theme.accent2)
        }
    }

    private func statCell(_ v: String, _ k: String, _ color: Color = Theme.fg) -> some View {
        VStack(spacing: 3) {
            Text(v).font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundColor(color)
            Text(k).font(.system(size: 10)).foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 11)
        .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
    }

    private var weakSection: some View {
        let weak = SUBJECTS.compactMap { s -> (String, Int)? in
            let v = result.perSubject[s] ?? [0, 0]
            guard v[1] > 0 else { return nil }
            let pct = Int((Double(v[0]) / Double(v[1]) * 100).rounded())
            return pct < 70 ? (s, pct) : nil
        }.sorted { $0.1 < $1.1 }

        return Group {
            if !weak.isEmpty {
                SectionHead(title: "弱点分析")
                ForEach(weak, id: \.0) { item in
                    HStack(alignment: .top, spacing: 11) {
                        Text(subjectShort(item.0))
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 9).padding(.vertical, 4)
                            .background(Theme.warn.opacity(0.18)).foregroundColor(Theme.warn)
                            .clipShape(Capsule())
                        Text("正答率 \(item.1)%。この分野を重点的に復習しましょう。")
                            .font(.system(size: 12)).foregroundColor(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
                }
            }
        }
    }

    private func dateStr(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "ja_JP"); f.dateFormat = "yyyy年M月d日"
        return f.string(from: d)
    }
    private func timeString(_ s: Int) -> String {
        s >= 3600 ? String(format: "%d:%02d:%02d", s/3600, (s%3600)/60, s%60)
                  : String(format: "%d:%02d", s/60, s%60)
    }
}
