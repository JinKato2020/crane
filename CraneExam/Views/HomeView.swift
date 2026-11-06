import SwiftUI

/// Detailed scores remain available from Home, without crowding its learning actions.
struct HomeProgressView: View {
    @EnvironmentObject private var store: ExamStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView { growthCard.padding(16) }
                .background(Theme.bg.ignoresSafeArea())
                .navigationTitle("学習の成績").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("閉じる") { dismiss() } } }
        }
    }
    // 成長レーダー：分野別の正答率を「現在／2週前／1ヶ月前」で3段比較。合否で色分け（40%未満=赤・合格圏=緑）。
    private var growthCard: some View {
        let now = store.subjectAccuracy()
        let cal = Calendar.current
        let d2w = cal.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let d1m = cal.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let twoW = store.results.contains { $0.date <= d2w } ? store.subjectAccuracy(asOf: d2w) : nil
        let oneM = store.results.contains { $0.date <= d1m } ? store.subjectAccuracy(asOf: d1m) : nil
        let weak = now.contains { $0.pct < 40 }
        let allPass = !weak && store.results.reduce(0) { $0 + $1.examScore } >= store.results.count * 60
        let nowColor = allPass ? Theme.good : Theme.warn
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("分野別の実力", systemImage: "chart.pie.fill")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(Theme.fg)
                    Spacer()
                    if !store.results.isEmpty {
                        Text(allPass ? "合格圏" : "弱点あり")
                            .font(.system(size: 12, weight: .heavy)).foregroundColor(nowColor)
                            .padding(.horizontal, 9).padding(.vertical, 4)
                            .background(nowColor.opacity(0.14)).clipShape(Capsule())
                    }
                }
                if store.results.isEmpty {
                    growthEmpty
                } else {
                    GrowthRadar(now: now, twoW: twoW, oneM: oneM, nowColor: nowColor)
                        .frame(maxWidth: .infinity)
                    growthLegend(twoW: twoW, oneM: oneM, nowColor: nowColor)
                    Text("各科目40%以上・全体60%以上で合格圏。40%未満の科目は赤で表示します。")
                        .font(.system(size: 11)).foregroundColor(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var growthEmpty: some View {
        VStack(spacing: 7) {
            Image(systemName: "chart.dots.scatter").font(.system(size: 26)).foregroundColor(Theme.faint)
            Text("模試を受けると、分野別の実力と成長がここに表示されます。")
                .font(.system(size: 12)).foregroundColor(Theme.muted)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 18)
    }

    private enum LegendStyle { case solid, dashed, dotted }

    private func growthLegend(twoW: [(name: String, pct: Int)]?, oneM: [(name: String, pct: Int)]?, nowColor: Color) -> some View {
        HStack(spacing: 16) {
            legendItem(.solid, nowColor, "現在")
            if twoW != nil { legendItem(.dashed, Theme.accent2, "2週前") }
            if oneM != nil { legendItem(.dotted, Theme.faint, "1ヶ月前") }
            Spacer()
        }
    }

    private func legendItem(_ style: LegendStyle, _ color: Color, _ text: String) -> some View {
        HStack(spacing: 6) {
            legendSwatch(style, color)
            Text(text).font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.muted)
        }
    }

    @ViewBuilder private func legendSwatch(_ style: LegendStyle, _ color: Color) -> some View {
        switch style {
        case .solid:
            RoundedRectangle(cornerRadius: 1).fill(color).frame(width: 18, height: 3)
        case .dashed:
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in RoundedRectangle(cornerRadius: 1).fill(color).frame(width: 4, height: 3) }
            }
        case .dotted:
            HStack(spacing: 3) {
                ForEach(0..<4, id: \.self) { _ in Circle().fill(color).frame(width: 3, height: 3) }
            }
        }
    }

}

/// 分野別正答率のレーダー。現在（実線・合否色）／2週前（破線）／1ヶ月前（点線）を重ねて成長を見せる。
private struct GrowthRadar: View {
    let now: [(name: String, pct: Int)]
    let twoW: [(name: String, pct: Int)]?
    let oneM: [(name: String, pct: Int)]?
    let nowColor: Color
    var size: CGFloat = 200

    var body: some View {
        Canvas { ctx, sz in drawChart(&ctx, size: sz) }
            .frame(width: size, height: size)
    }

    private func shortName(_ s: String) -> String {
        switch s {
        case "クレーンに関する知識": return "クレーン"
        case "原動機・電気":       return "電気"
        case "関係法令":           return "法令"
        default:                   return s
        }
    }
    private func axisPoint(cx: Double, cy: Double, radius: Double, i: Int, n: Int, frac: Double) -> CGPoint {
        let ang: Double = -Double.pi / 2 + 2 * Double.pi * Double(i) / Double(n)
        return CGPoint(x: cx + cos(ang) * radius * frac, y: cy + sin(ang) * radius * frac)
    }
    private func ringPath(cx: Double, cy: Double, radius: Double, n: Int, frac: Double) -> Path {
        var p = Path()
        for i in 0..<n {
            let q = axisPoint(cx: cx, cy: cy, radius: radius, i: i, n: n, frac: frac)
            if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
        }
        p.closeSubpath(); return p
    }
    private func seriesPath(_ series: [(name: String, pct: Int)], cx: Double, cy: Double, radius: Double, n: Int) -> Path {
        var p = Path()
        for i in 0..<n {
            let frac: Double = max(0.02, Double(series[i].pct) / 100.0)
            let q = axisPoint(cx: cx, cy: cy, radius: radius, i: i, n: n, frac: frac)
            if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
        }
        p.closeSubpath(); return p
    }

    // 描画本体は some View の型推論の外（Void関数）へ。Canvas内の長い式をbody直書きにすると型チェックが破綻する（既知の失敗要因）。
    private func drawChart(_ ctx: inout GraphicsContext, size sz: CGSize) {
        let n = max(3, now.count)
        let cx = Double(sz.width) / 2
        let cy = Double(sz.height) / 2
        let radius = Double(min(sz.width, sz.height)) / 2 - 50
        let center = CGPoint(x: cx, y: cy)

        // 目盛り（25/50/75/100%）
        for k in 1...4 {
            let frac = Double(k) / 4.0
            let ring = ringPath(cx: cx, cy: cy, radius: radius, n: n, frac: frac)
            let op: Double = (k == 4) ? 0.8 : 0.3
            let lw: Double = (k == 4) ? 1.2 : 0.7
            ctx.stroke(ring, with: .color(Theme.line.opacity(op)), lineWidth: lw)
        }
        // 40%の合格ライン（赤系の点線で強調）
        let passRing = ringPath(cx: cx, cy: cy, radius: radius, n: n, frac: 0.40)
        ctx.stroke(passRing, with: .color(Theme.warn.opacity(0.5)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        // スポーク
        for i in 0..<n {
            var p = Path()
            p.move(to: center)
            p.addLine(to: axisPoint(cx: cx, cy: cy, radius: radius, i: i, n: n, frac: 1.0))
            ctx.stroke(p, with: .color(Theme.line.opacity(0.4)), lineWidth: 0.7)
        }
        // 1ヶ月前（点線）
        if let m = oneM {
            let path = seriesPath(m, cx: cx, cy: cy, radius: radius, n: n)
            ctx.stroke(path, with: .color(Theme.faint), style: StrokeStyle(lineWidth: 1.6, dash: [2, 4]))
        }
        // 2週前（破線）
        if let w = twoW {
            let path = seriesPath(w, cx: cx, cy: cy, radius: radius, n: n)
            ctx.stroke(path, with: .color(Theme.accent2), style: StrokeStyle(lineWidth: 1.8, dash: [6, 4]))
        }
        // 現在（実線＋塗り・合否色）
        let dp = seriesPath(now, cx: cx, cy: cy, radius: radius, n: n)
        ctx.fill(dp, with: .color(nowColor.opacity(0.22)))
        ctx.stroke(dp, with: .color(nowColor), lineWidth: 2.4)
        for i in 0..<n {
            let frac: Double = max(0.02, Double(now[i].pct) / 100.0)
            let q = axisPoint(cx: cx, cy: cy, radius: radius, i: i, n: n, frac: frac)
            let dotColor = now[i].pct <= 40 ? Theme.warn : nowColor
            let dot = CGRect(x: q.x - 3.2, y: q.y - 3.2, width: 6.4, height: 6.4)
            ctx.fill(Path(ellipseIn: dot), with: .color(dotColor))
        }
        // ラベル（分野名＋現在%）。40%以下は赤、合格圏は緑。
        for i in 0..<n {
            let ang: Double = -Double.pi / 2 + 2 * Double.pi * Double(i) / Double(n)
            let lx = cx + cos(ang) * (radius + 22)
            let ly = cy + sin(ang) * (radius + 16)
            let weak = now[i].pct <= 40
            let nameText = Text(shortName(now[i].name)).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.fg)
            let pctText = Text("\(now[i].pct)%").font(.system(size: 12.5, weight: .heavy)).foregroundColor(weak ? Theme.warn : Theme.good)
            ctx.draw(nameText, at: CGPoint(x: lx, y: ly - 7))
            ctx.draw(pctText, at: CGPoint(x: lx, y: ly + 8))
        }
    }
}

/// 試験日を設定するシート（日付ピッカー）。保存値は timeIntervalSince1970。
struct ExamDateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var examEpoch: Double
    @State private var date: Date

    init(examEpoch: Binding<Double>) {
        _examEpoch = examEpoch
        let stored = examEpoch.wrappedValue
        let d0 = stored > 0 ? Date(timeIntervalSince1970: stored) : Date()
        _date = State(initialValue: max(d0, Date()))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                DatePicker("試験日", selection: $date, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Theme.accent)
                    .padding(.horizontal, 4)

                Button {
                    examEpoch = Calendar.current.startOfDay(for: date).timeIntervalSince1970
                    dismiss()
                } label: {
                    Text("この日に設定").font(.system(size: 15, weight: .heavy))
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                        .foregroundColor(Color(hex: 0x241703)).background(Theme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if examEpoch > 0 {
                    Button(role: .destructive) {
                        examEpoch = 0; dismiss()
                    } label: {
                        Text("試験日の設定を消す").font(.system(size: 13.5, weight: .bold))
                    }
                }
                Spacer()
            }
            .padding(16)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("試験日の設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("閉じる") { dismiss() } } }
        }
    }
}
