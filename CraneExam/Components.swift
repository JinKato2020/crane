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

    var body: some View {
        Canvas { ctx, sz in
            let n = max(3, data.count)
            let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
            let r = min(sz.width, sz.height) / 2 - 34   // 外周ラベルの余白
            func pt(_ i: Int, _ f: CGFloat) -> CGPoint {
                let a = -CGFloat.pi / 2 + 2 * CGFloat.pi * CGFloat(i) / CGFloat(n)
                return CGPoint(x: c.x + cos(a) * r * f, y: c.y + sin(a) * r * f)
            }
            // 目盛りの多角形（25/50/75/100%）
            for k in 1...4 {
                let ring = CGFloat(k) / 4
                var p = Path()
                for i in 0..<n { let q = pt(i, ring); if i == 0 { p.move(to: q) } else { p.addLine(to: q) } }
                p.closeSubpath()
                ctx.stroke(p, with: .color(Theme.line.opacity(k == 4 ? 0.8 : 0.33)), lineWidth: k == 4 ? 1.2 : 0.7)
            }
            // 各軸（スポーク）
            for i in 0..<n {
                var p = Path(); p.move(to: c); p.addLine(to: pt(i, 1))
                ctx.stroke(p, with: .color(Theme.line.opacity(0.45)), lineWidth: 0.7)
            }
            // データ多角形
            var dp = Path()
            for i in 0..<n {
                let f = max(0.02, CGFloat(data[i].pct) / 100)
                let q = pt(i, f); if i == 0 { dp.move(to: q) } else { dp.addLine(to: q) }
            }
            dp.closeSubpath()
            ctx.fill(dp, with: .color(Theme.gold.opacity(0.30)))
            ctx.stroke(dp, with: .color(Theme.gold), lineWidth: 2)
            for i in 0..<n {
                let f = max(0.02, CGFloat(data[i].pct) / 100)
                let q = pt(i, f)
                ctx.fill(Path(ellipseIn: CGRect(x: q.x - 3, y: q.y - 3, width: 6, height: 6)), with: .color(Theme.gold))
            }
            // ラベル（分野名＋％）
            for i in 0..<n {
                let a = -CGFloat.pi / 2 + 2 * CGFloat.pi * CGFloat(i) / CGFloat(n)
                let lx = c.x + cos(a) * (r + 20)
                let ly = c.y + sin(a) * (r + 16)
                ctx.draw(Text(shortName(data[i].name)).font(.system(size: 10.5, weight: .bold)).foregroundColor(Theme.fg),
                         at: CGPoint(x: lx, y: ly - 6), anchor: .center)
                ctx.draw(Text("\(data[i].pct)%").font(.system(size: 10.5, weight: .heavy)).foregroundColor(Theme.accent2),
                         at: CGPoint(x: lx, y: ly + 6), anchor: .center)
            }
        }
        .frame(width: size, height: size)
    }
}
