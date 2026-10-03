import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: ExamStore
    @EnvironmentObject var router: Router

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                VStack(spacing: 13) {
                    progressCard
                    cardsGrid
                    chips
                    Text("挑戦が、現場を動かす。")
                        .font(.system(size: 11)).foregroundColor(Theme.faint)
                        .frame(maxWidth: .infinity).padding(.top, 6)
                }
                .padding(16)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    // ヒーロー
    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            Image("Hero")
                .resizable().aspectRatio(contentMode: .fill)
                .frame(height: 220).frame(maxWidth: .infinity).clipped()
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
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    // 進捗カード
    private var progressCard: some View {
        Card {
            VStack(spacing: 14) {
                HStack(spacing: 16) {
                    Ring(progress: Double(store.progress) / 100,
                         size: 92, label: "\(store.progress)%", sub: "達成度")
                    VStack(spacing: 9) {
                        statRow("受験した回数", "\(store.examsTaken)", "/8回", Theme.fg)
                        Divider().overlay(Theme.line)
                        statRow("解いた問題数", "\(store.totalAnswered)", "問", Theme.fg)
                        Divider().overlay(Theme.line)
                        statRow("正答率", "\(store.accuracy)", "%", Theme.accent2)
                    }
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
            homeCard("square.grid.2x2.fill", "分野別問題", "苦手が分かる・克服する") { router.studySeg = 1; router.tab = 1 }
            homeCard("doc.text.fill", "模擬試験", "本番形式で力試し") { router.studySeg = 0; router.tab = 1 }
            homeCard("arrow.counterclockwise", "弱点復習", "間違えた問題をもう一度") { router.noteSeg = 0; router.tab = 3 }
            homeCard("bookmark.fill", "ブックマーク", "あとで見返す問題") { router.noteSeg = 1; router.tab = 3 }
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

    // 分野チップ
    private var chips: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHead(title: "分野から選ぶ")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(SUBJECTS, id: \.self) { s in
                        Button { router.studySeg = 1; router.tab = 1 } label: {
                            HStack(spacing: 8) {
                                Circle().fill(Theme.subjectColor(s)).frame(width: 7, height: 7)
                                Text(s).font(.system(size: 12.5, weight: .bold)).foregroundColor(Theme.fg)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .background(Theme.card)
                            .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }
}
