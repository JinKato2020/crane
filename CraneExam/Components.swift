import SwiftUI

/// 枠付きカード
struct Card<Content: View>: View {
    var padding: CGFloat = 15
    var radius: CGFloat = 14
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }
}

/// 円グラフ（達成度・得点）
struct Ring: View {
    var progress: Double
    var size: CGFloat = 92
    var line: CGFloat = 9
    var label: String
    var sub: String
    var body: some View {
        ZStack {
            Circle().stroke(Theme.raise, lineWidth: line)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(Theme.gold, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text(label)
                    .font(.system(size: size * 0.30, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.fg)
                Text(sub)
                    .font(.system(size: max(9, size * 0.11)))
                    .foregroundColor(Theme.muted)
            }
        }
        .frame(width: size, height: size)
    }
}

/// 分野別の横棒
struct BarRow: View {
    var name: String
    var pct: Int
    var body: some View {
        HStack(spacing: 12) {
            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.fg)
                .frame(width: 70, alignment: .leading)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.raise)
                    Capsule().fill(Theme.gold)
                        .frame(width: max(6, g.size.width * CGFloat(pct) / 100))
                }
            }
            .frame(height: 8)
            Text("\(pct)%")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.accent2)
                .frame(width: 42, alignment: .trailing)
        }
        .frame(height: 24)
    }
}

/// 小さなラベル
struct Pill: View {
    var text: String
    var fg: Color
    var bg: Color
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(bg).foregroundColor(fg)
            .clipShape(Capsule())
    }
}

/// セクション見出し
struct SectionHead: View {
    var title: String
    var trailing: String? = nil
    var body: some View {
        HStack {
            Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(Theme.fg)
            Spacer()
            if let t = trailing {
                Text(t).font(.system(size: 12)).foregroundColor(Theme.muted)
            }
        }
    }
}

/// 間違えた問題・ブックマークの一覧カード（タップで問題の詳細を開く）。
struct QCard: View {
    @EnvironmentObject var store: ExamStore
    let round: Int
    let q: Question
    var tagColor: Color
    var tagText: String
    var showBookmarkToggle: Bool = false
    let onTap: () -> Void

    private var bmID: String { "\(round)-\(q.no)" }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 10) {
                Text("第\(round)回 問\(q.no) · \(subjectShort(q.subject))")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(Theme.fg)
                Spacer()
                Pill(text: tagText, fg: tagColor, bg: tagColor.opacity(0.18))
                if showBookmarkToggle {
                    Button { store.toggleBookmark(bmID) } label: {
                        Image(systemName: store.isBookmarked(bmID) ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(store.isBookmarked(bmID) ? Theme.accent2 : Theme.muted)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(store.isBookmarked(bmID) ? "ブックマーク解除" : "ブックマークに追加")
                }
            }
            Text(q.text).font(.system(size: 13)).foregroundColor(Theme.muted)
                .lineLimit(3).lineSpacing(2).fixedSize(horizontal: false, vertical: true)
            if q.answer - 1 < q.choices.count {
                Text("正解 (\(q.answer)) \(q.choices[q.answer - 1])")
                    .font(.system(size: 12.5, weight: .semibold)).foregroundColor(Theme.good)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

/// 分野別の正答率を表すレーダーチャート（各分野＝1軸）。データは store.subjectAccuracy() を渡す。
struct RadarChart: View {
    let data: [(name: String, pct: Int)]
    var size: CGFloat = 196

    private func shortName(_ s: String) -> String {
        switch s {
        case "クレーンに関する知識": return "クレーン"
        case "原動機・電気":       return "電気"
        case "関係法令":           return "法令"
        default:                   return s
        }
    }

    // 中心・半径・各軸の点（Doubleで計算し、式を分解して型チェックを軽くする）
    private func axisPoint(cx: Double, cy: Double, radius: Double, i: Int, n: Int, frac: Double) -> CGPoint {
        let ang: Double = -Double.pi / 2 + 2 * Double.pi * Double(i) / Double(n)
        let x: Double = cx + cos(ang) * radius * frac
        let y: Double = cy + sin(ang) * radius * frac
        return CGPoint(x: x, y: y)
    }

    private func polygonPath(cx: Double, cy: Double, radius: Double, n: Int, frac: Double) -> Path {
        var p = Path()
        for i in 0..<n {
            let q = axisPoint(cx: cx, cy: cy, radius: radius, i: i, n: n, frac: frac)
            if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
        }
        p.closeSubpath()
        return p
    }

    private func dataPath(cx: Double, cy: Double, radius: Double, n: Int) -> Path {
        var p = Path()
        for i in 0..<n {
            let frac: Double = max(0.02, Double(data[i].pct) / 100.0)
            let q = axisPoint(cx: cx, cy: cy, radius: radius, i: i, n: n, frac: frac)
            if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
        }
        p.closeSubpath()
        return p
    }

    var body: some View {
        Canvas { ctx, sz in
            drawChart(&ctx, size: sz)
        }
        .frame(width: size, height: size)
    }

    // 描画本体は some View の型推論の外（ただのVoid関数）に出す。
    // Canvas 内の長い式を body に直書きすると型チェックが破綻する（build 2012/2013の失敗原因）。
    private func drawChart(_ ctx: inout GraphicsContext, size sz: CGSize) {
            let n = max(3, data.count)
            let cx = Double(sz.width) / 2
            let cy = Double(sz.height) / 2
            let radius = Double(min(sz.width, sz.height)) / 2 - 34
            let center = CGPoint(x: cx, y: cy)
            // Theme.gold は LinearGradient なので Canvas の .color() には渡せない。
            // Canvas 内ではブランドゴールドの単色を使う。
            let gold = Color(hex: 0xF6A425)

            // 目盛りの多角形（25/50/75/100%）
            for k in 1...4 {
                let frac = Double(k) / 4.0
                let ring = polygonPath(cx: cx, cy: cy, radius: radius, n: n, frac: frac)
                let op: Double = (k == 4) ? 0.8 : 0.33
                let lw: Double = (k == 4) ? 1.2 : 0.7
                ctx.stroke(ring, with: .color(Theme.line.opacity(op)), lineWidth: lw)
            }
            // 各軸（スポーク）
            for i in 0..<n {
                var p = Path()
                p.move(to: center)
                p.addLine(to: axisPoint(cx: cx, cy: cy, radius: radius, i: i, n: n, frac: 1.0))
                ctx.stroke(p, with: .color(Theme.line.opacity(0.45)), lineWidth: 0.7)
            }
            // データ多角形
            let dp = dataPath(cx: cx, cy: cy, radius: radius, n: n)
            ctx.fill(dp, with: .color(gold.opacity(0.30)))
            ctx.stroke(dp, with: .color(gold), lineWidth: 2)
            // 頂点
            for i in 0..<n {
                let frac: Double = max(0.02, Double(data[i].pct) / 100.0)
                let q = axisPoint(cx: cx, cy: cy, radius: radius, i: i, n: n, frac: frac)
                let dot = CGRect(x: q.x - 3, y: q.y - 3, width: 6, height: 6)
                ctx.fill(Path(ellipseIn: dot), with: .color(gold))
            }
            // ラベル（分野名＋％）
            for i in 0..<n {
                let ang: Double = -Double.pi / 2 + 2 * Double.pi * Double(i) / Double(n)
                let lx = cx + cos(ang) * (radius + 20)
                let ly = cy + sin(ang) * (radius + 14)
                let nameText = Text(shortName(data[i].name)).font(.system(size: 10.5, weight: .bold)).foregroundColor(Theme.fg)
                let pctText = Text("\(data[i].pct)%").font(.system(size: 10.5, weight: .heavy)).foregroundColor(Theme.accent2)
                ctx.draw(nameText, at: CGPoint(x: lx, y: ly - 6))
                ctx.draw(pctText, at: CGPoint(x: lx, y: ly + 6))
            }
    }
}
