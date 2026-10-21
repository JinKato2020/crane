import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: ExamStore
    @EnvironmentObject var router: Router
    @State private var showGuide = false
    @State private var showBookmarks = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                VStack(spacing: 13) {
                    progressCard
                    guideCard
                    cardsGrid
                    Text("挑戦が、現場を動かす。")
                        .font(.system(size: 11)).foregroundColor(Theme.faint)
                        .frame(maxWidth: .infinity).padding(.top, 6)
                }
                .padding(16)
            }
        }
        .ignoresSafeArea(edges: .top)   // ヒーローを画面最上端まで伸ばし、上の白い余白を無くす
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showGuide) { ExamGuideView() }
        .sheet(isPresented: $showBookmarks) { BookmarkView().environmentObject(store) }
    }

    // 総合解説カード（CAE流用：写真背景＋オーバーレイ）
    private var guideCard: some View {
        Button { showGuide = true } label: {
            ZStack(alignment: .bottomLeading) {
                Image("ExamGuideBg")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 112)
                    .clipped()
                LinearGradient(colors: [Color.black.opacity(0.12), Color.black.opacity(0.74)],
                               startPoint: .top, endPoint: .bottom)
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("クレーン試験 総合解説")
                            .font(.system(size: 15.5, weight: .heavy)).foregroundColor(.white)
                        Text("配点・合格基準・学び方がひと目でわかる")
                            .font(.system(size: 11.5, weight: .semibold)).foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 6)
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundColor(.white.opacity(0.9))
                }
                .padding(14)
                .shadow(color: .black.opacity(0.6), radius: 4, y: 1)
            }
            .frame(height: 112)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.line, lineWidth: 1))
        }
    }

    // ヒーロー(画像全体を切らずに表示=fit。上に余白を作らず横幅いっぱい・縦は縦横比なり)
    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            Image("Hero")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
            LinearGradient(
                colors: [Color.black.opacity(0.45), Color.clear, Theme.bg],
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

    // 進捗カード
    private var progressCard: some View {
        Card {
            VStack(spacing: 14) {
                HStack {
                    Text("分野別の正答率").font(.system(size: 14, weight: .bold)).foregroundColor(Theme.fg)
                    Spacer()
                    Text("全体 \(store.accuracy)%").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.accent2)
                }
                if store.totalAnswered == 0 {
                    VStack(spacing: 6) {
                        Image(systemName: "chart.dots.scatter").font(.system(size: 30)).foregroundColor(Theme.faint)
                        Text("模擬試験を受けると、分野別の正答率が表示されます")
                            .font(.system(size: 11.5)).foregroundColor(Theme.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).frame(height: 150)
                } else {
                    RadarChart(data: store.subjectAccuracy(), size: 196)
                        .frame(maxWidth: .infinity)
                }
                VStack(spacing: 9) {
                    statRow("受験した回数", "\(store.examsTaken)", "/\(store.examTotal)回", Theme.fg)
                    Divider().overlay(Theme.line)
                    statRow("解いた問題数", "\(store.totalAnswered)", "問", Theme.fg)
                    Divider().overlay(Theme.line)
                    statRow("正答率", "\(store.accuracy)", "%", Theme.accent2)
                }
                Button {
                    router.tab = 1
                } label: {
                    HStack(spacing: 13) {
                        Image(systemName: "book.fill")
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.22))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("学習を始める").font(.system(size: 15, weight: .heavy))
                            Text("確かな一歩、合格へ").font(.system(size: 11, weight: .bold)).opacity(0.75)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(Color(hex: 0x241703))
                    .padding(15)
                    .background(Theme.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private func statRow(_ k: String, _ v: String, _ unit: String, _ color: Color) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(k).font(.system(size: 12)).foregroundColor(Theme.muted)
            Spacer()
            Text(v).font(.system(size: 19, weight: .semibold, design: .rounded)).foregroundColor(color)
            Text(unit).font(.system(size: 11)).foregroundColor(Theme.muted)
        }
    }

    // 2x2 カード
    private var cardsGrid: some View {
        let cols = [GridItem(.flexible(), spacing: 11), GridItem(.flexible(), spacing: 11)]
        return LazyVGrid(columns: cols, spacing: 11) {
            homeCard("book.fill", "教材で学ぶ", "全4章の解説・図表") { router.tab = 1 }
            homeCard("character.book.closed.fill", "用語集", "全4章の重要用語") { router.tab = 3 }
            homeCard("doc.text.fill", "模擬試験", "本番形式で力試し") { router.tab = 2 }
            homeCard("chart.bar.xaxis", "分野別の到達度", "苦手が一目でわかる") { router.tab = 2 }
            homeCard("arrow.counterclockwise", "弱点復習", "模試ごとに間違いを確認") { router.tab = 2 }
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
