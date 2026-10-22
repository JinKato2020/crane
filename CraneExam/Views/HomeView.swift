import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var store: ExamStore
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
                    relationMapCard
                    guideCard
                    cardsGrid
                    motivationFooter
                }
                .padding(16)
            }
        }
        .background(Theme.bg.ignoresSafeArea())   // 背景は最上端まで(白余白なし)。ヒーロー自体はステータスバー下に収め、クレーン上部まで見えるようにする
        .sheet(isPresented: $showGuide) { ExamGuideView() }
        .sheet(isPresented: $showRelationMap) { ChapterRelationMapView().environmentObject(store) }
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

    // 4章の全体像を、ホームから直接拡大して読めるカード。
    private var relationMapCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("相関図", systemImage: "point.3.connected.trianglepath.dotted")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.fg)
                    Spacer()
                    Text("タップで拡大")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.muted)
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 16) {
                    ForEach(1...4, id: \.self) { number in
                        VStack(alignment: .leading, spacing: 7) {
                            Text("第\(number)章 · \(["クレーン", "関係法令", "電気・電動機", "力学"][number - 1])")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.fg)
                                .fixedSize(horizontal: false, vertical: true)
                            SVGFigureView(file: "chapter\(number)_relation_map.svg", caption: "第\(number)章の相関図", thumbMaxHeight: 180)
                        }
                    }
                }
            }
        }
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
