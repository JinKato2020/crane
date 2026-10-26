import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var store: ExamStore
    @EnvironmentObject var purchases: PurchaseStore
    @EnvironmentObject var router: Router
    @State private var showGuide = false
    @State private var showRelationMap = false
    @State private var showBookmarks = false
    @State private var showFavTerms = false
    @AppStorage("cr_exam_date") private var examEpoch: Double = 0   // 試験日(0=未設定, timeIntervalSince1970)
    @State private var showDateSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                VStack(spacing: 13) {
                    countdownCard
                    growthCard
                    cardsGrid
                    guideCard
                    streakCard
                    motivationFooter
                }
                .padding(16)
            }
        }
        .background(Theme.bg.ignoresSafeArea())   // 背景は最上端まで(白余白なし)。ヒーロー自体はステータスバー下に収め、クレーン上部まで見えるようにする
        .sheet(isPresented: $showGuide) { ExamGuideView() }
        .sheet(isPresented: $showRelationMap) { ChapterRelationMapView().environmentObject(store).environmentObject(purchases) }
        .sheet(isPresented: $showBookmarks) { BookmarkView().environmentObject(store) }
        .sheet(isPresented: $showFavTerms) { FavoriteTermsScreen().environmentObject(store) }
        .sheet(isPresented: $showDateSheet) { ExamDateSheet(examEpoch: $examEpoch) }
    }

    // 外観別の写真とオーバーレイで、ホームの背景と文字の読みやすさをそろえる。
    private var guideCard: some View {
        Button { showGuide = true } label: {
            ZStack(alignment: .bottomLeading) {
                Image("ExamGuideBg")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 112)
                    .clipped()
                LinearGradient(colors: colorScheme == .dark
                               ? [Color.black.opacity(0.12), Color.black.opacity(0.74)]
                               : [Color.white.opacity(0.08), Color.white.opacity(0.92)],
                               startPoint: .top, endPoint: .bottom)
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("クレーン試験 総合解説")
                            .font(.system(size: 15.5, weight: .heavy)).foregroundColor(guideTextColor)
                        Text("配点・合格基準・学び方がひと目でわかる")
                            .font(.system(size: 11.5, weight: .semibold)).foregroundColor(guideTextColor.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 6)
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundColor(guideTextColor.opacity(0.9))
                }
                .padding(14)
                .shadow(color: colorScheme == .dark ? .black.opacity(0.6) : .clear, radius: 4, y: 1)
            }
            .frame(height: 112)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.line, lineWidth: 1))
        }
    }

    private var guideTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: 0x1F3349)
    }

    // ヒーロー(画像全体を切らずに表示=fit。上に余白を作らず横幅いっぱい・縦は縦横比なり)
    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            Image("Hero")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
            LinearGradient(
                colors: [Color.black.opacity(0.18), Color.clear, Theme.bg],
                startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 4) {
                Text("KNOWLEDGE BUILDS TOMORROW")
                    .font(.system(size: 10, weight: .semibold)).tracking(2)
                    .foregroundColor(Theme.accent2)
                Text("クレーン・デリック運転士 試験対策")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("確かな知識で、安全な現場をつくる。")
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.85))
            }
            .shadow(color: .black.opacity(0.7), radius: 8)
            .padding(16)
        }
        .frame(maxWidth: .infinity)
    }

    // 試験までの残り日数（ヒーロー直下に大きく表示）。未設定ならタップで設定を促す。
    private var examDate: Date? { examEpoch > 0 ? Date(timeIntervalSince1970: examEpoch) : nil }
    private var daysLeft: Int? {
        guard let d = examDate else { return nil }
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: d)).day
    }
    private func examDateText(_ d: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月d日(E)"
        return f.string(from: d)
    }
    private var inkColor: Color { Color(hex: 0x241703) }   // ゴールド地に合う濃茶文字

    private var countdownCard: some View {
        Button { showDateSheet = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "calendar")
                    .font(.system(size: 20, weight: .bold)).foregroundColor(inkColor)
                    .frame(width: 46, height: 46)
                    .background(Color.white.opacity(0.28)).clipShape(RoundedRectangle(cornerRadius: 12))
                countdownBody
                Spacer(minLength: 6)
                Image(systemName: daysLeft == nil ? "plus.circle.fill" : "pencil.circle.fill")
                    .font(.system(size: 18, weight: .bold)).foregroundColor(inkColor.opacity(0.75))
            }
            .padding(15)
            .frame(maxWidth: .infinity)
            .background(Theme.gold)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder private var countdownBody: some View {
        if let n = daysLeft {
            VStack(alignment: .leading, spacing: 2) {
                if n > 0 {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("試験まで").font(.system(size: 12, weight: .bold)).foregroundColor(inkColor.opacity(0.8))
                        Text("あと\(n)日").font(.system(size: 22, weight: .heavy)).foregroundColor(inkColor)
                    }
                } else if n == 0 {
                    Text("試験当日です").font(.system(size: 20, weight: .heavy)).foregroundColor(inkColor)
                } else {
                    Text("試験日は過ぎました").font(.system(size: 17, weight: .heavy)).foregroundColor(inkColor)
                }
                if let d = examDate {
                    Text(examDateText(d)).font(.system(size: 11.5, weight: .semibold)).foregroundColor(inkColor.opacity(0.8))
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text("試験日を設定").font(.system(size: 16, weight: .heavy)).foregroundColor(inkColor)
                Text("残り日数をここに大きく表示します").font(.system(size: 11.5, weight: .semibold)).foregroundColor(inkColor.opacity(0.8))
            }
        }
    }

    // 成長レーダー：分野別の正答率を「現在／2週前／1ヶ月前」で3段比較。合否で色分け（40%以下=赤・合格圏=緑）。
    private var growthCard: some View {
        let now = store.subjectAccuracy()
        let cal = Calendar.current
        let d2w = cal.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let d1m = cal.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let twoW = store.results.contains { $0.date <= d2w } ? store.subjectAccuracy(asOf: d2w) : nil
        let oneM = store.results.contains { $0.date <= d1m } ? store.subjectAccuracy(asOf: d1m) : nil
        let weak = now.contains { $0.pct <= 40 }
        let allPass = !weak && store.accuracy >= 60
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
                    Text("各科目40%以上・全体60%以上で合格圏。40%以下の科目は赤で表示します。")
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

    // ホーム最下部の“決めゼリフ”。ゴールドのグラデ文字＋英語キッカーでモチベを上げる。
    private var motivationFooter: some View {
        VStack(spacing: 9) {
            HStack(spacing: 8) {
                Rectangle().fill(Theme.gold).frame(width: 22, height: 2).opacity(0.9)
                Image(systemName: "flame.fill").font(.system(size: 11)).foregroundStyle(Theme.gold)
                Rectangle().fill(Theme.gold).frame(width: 22, height: 2).opacity(0.9)
            }
            Text("挑戦が、現場を動かす。")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(Theme.gold)
                .shadow(color: Theme.accent.opacity(0.25), radius: 6, y: 1)
            Text("CHALLENGE MOVES THE FIELD")
                .font(.system(size: 9, weight: .bold)).tracking(2.5)
                .foregroundColor(Theme.faint)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16).padding(.bottom, 4)
    }

    // 学習の継続カード：直近14日の「解いた問題数」を棒で示し、連続学習日数を添える。
    private var streakCard: some View {
        let data = store.recentDaily(14)
        let maxC = max(data.map { $0.count }.max() ?? 0, 1)
        let streak = store.studyStreak
        return Card {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    Label("学習の継続", systemImage: "flame.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.fg)
                    Spacer()
                    Text(streak > 0 ? "\(streak)日連続" : "今日から始めよう")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(streak > 0 ? Theme.accent2 : Theme.muted)
                }
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(item.count > 0 ? AnyShapeStyle(Theme.gold) : AnyShapeStyle(Theme.line))
                            .frame(maxWidth: .infinity)
                            .frame(height: barHeight(item.count, maxC))
                    }
                }
                .frame(height: 56, alignment: .bottom)
                HStack {
                    Text("14日前").font(.system(size: 10)).foregroundColor(Theme.faint)
                    Spacer()
                    Text("今日").font(.system(size: 10)).foregroundColor(Theme.faint)
                }
                Text("解いた問題数の推移。毎日つづけて、連続日数をのばそう。")
                    .font(.system(size: 11)).foregroundColor(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    private func barHeight(_ c: Int, _ maxC: Int) -> CGFloat {
        let minH: CGFloat = 4, maxH: CGFloat = 52
        guard c > 0 else { return minH }
        return minH + (maxH - minH) * CGFloat(c) / CGFloat(maxC)
    }

    // 2x2 カード
    private var cardsGrid: some View {
        let cols = [GridItem(.flexible(), spacing: 11), GridItem(.flexible(), spacing: 11)]
        return LazyVGrid(columns: cols, spacing: 11) {
            homeCard("book.fill", "教材で学ぶ", "全4章の解説・図表") { router.tab = 1 }
            homeCard("character.book.closed.fill", "用語集", "全4章の重要用語") { router.tab = 3 }
            homeCard("doc.text.fill", "模擬試験", "本番形式で力試し") { router.tab = 2 }
            homeCard("point.3.connected.trianglepath.dotted", "相関図", "第1〜4章のつながりをつかむ") { showRelationMap = true }
            homeCard("heart.fill", "お気に入りの用語", "ハートを付けた用語を見直す") { showFavTerms = true }
            homeCard("bookmark.fill", "ブックマーク", "あとで見返す問題") { showBookmarks = true }
        }
    }

    private func homeCard(_ icon: String, _ title: String, _ sub: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                Image(systemName: icon)
                    .foregroundColor(Theme.accent)
                    .frame(width: 36, height: 36)
                    .background(Theme.raise).clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.bottom, 6)
                Text(title).font(.system(size: 13.5, weight: .bold)).foregroundColor(Theme.fg)
                Text(sub).font(.system(size: 11)).foregroundColor(Theme.faint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
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
private struct ExamDateSheet: View {
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
