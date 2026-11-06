import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject private var store: ExamStore
    @EnvironmentObject private var purchases: PurchaseStore
    @EnvironmentObject private var router: Router
    @Environment(\.dynamicTypeSize) private var typeSize
    @AppStorage(HomeHeroCatalog.preferenceKey) private var heroID = ""
    @AppStorage("cr_exam_date") private var examEpoch: Double = 0
    @AppStorage("cr_free_welcome_seen") private var welcomeSeen = false
    @State private var showHeroPicker = false
    @State private var showDate = false
    @State private var showGuide = false
    @State private var showMap = false
    @State private var showBookmarks = false
    @State private var showFavorites = false
    @State private var showProgress = false
    @State private var resumePlace: StudyPlace?

    private var showWelcome: Bool { purchases.hasLifetimeFreeAccess && !purchases.hasPaidPro && !welcomeSeen }
    private var hero: HomeHero? { store.homeHeroes.hero(for: heroID) }
    private var nextPlace: StudyPlace? {
        if let place = store.lastStudyPlace {
            switch place.kind {
            case .textbook:
                if let chapter = store.textbook?.chapters.first(where: { $0.sections.contains { $0.id == place.sectionID } }),
                   let section = chapter.sections.first(where: { $0.id == place.sectionID }) {
                    return StudyPlace(kind: .textbook, title: section.title, chapterID: chapter.id, sectionID: section.id)
                }
            case .glossary:
                if let chapter = store.textbook?.chapters.first(where: { $0.id == place.chapterID }) {
                    return StudyPlace(kind: .glossary, title: "第\(chapter.id)章の用語", chapterID: chapter.id)
                }
                return StudyPlace(kind: .glossary, title: "用語を確かめる")
            case .exam:
                return StudyPlace(kind: .exam, title: "模擬試験 第\(place.examRound ?? 1)回", examRound: place.examRound)
            }
        }
        guard let chapter = store.textbook?.chapters.first, let section = chapter.sections.first else { return nil }
        return StudyPlace(kind: .textbook, title: section.title, chapterID: chapter.id, sectionID: section.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                heroCard
                if showWelcome { welcomeCard } else { resumeCard }
                weekCard
                Text("学び方を選ぶ").font(.headline).foregroundColor(Theme.fg).padding(.top, 6)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 10) {
                    entry("book", "教材", "図と解説で理解する") { router.tab = 1 }
                    entry("character.book.closed", "用語", "大切な言葉を確かめる") { router.tab = 3 }
                    entry("doc.text", "模擬試験", "本番形式で力を試す") { router.tab = 2 }
                    entry("point.3.connected.trianglepath.dotted", "相関図", "知識のつながりを見る") { showMap = true }
                }
                savedRow
                utility("クレーン試験 総合解説", subtitle: "試験の全体像と、学び方がわかる", symbol: "info.circle") { showGuide = true }
                utility("学習の成績を見る", subtitle: "分野ごとの正答率と、これまでの変化", symbol: "chart.bar") { showProgress = true }
                Text("一度に全部でなくていい。\nひとつずつ、確かな知識に。")
                    .font(.footnote).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
            }.padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showHeroPicker) { HomeHeroPicker() }
        .sheet(isPresented: $showDate) { ExamDateSheet(examEpoch: $examEpoch) }
        .sheet(isPresented: $showGuide) { ExamGuideView() }
        .sheet(isPresented: $showMap) { ChapterRelationMapView() }
        .sheet(isPresented: $showBookmarks) { BookmarkView() }
        .sheet(isPresented: $showFavorites) { FavoriteTermsScreen().trackStudyCompletion(kind: .glossary) }
        .sheet(isPresented: $showProgress) { HomeProgressView() }
        .sheet(item: $resumePlace) { HomeResumeSheet(place: $0) }
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { brand; Spacer(minLength: 0); dateButton }
            VStack(alignment: .leading, spacing: 10) { brand; dateButton }
        }.padding(.vertical, 4)
    }
    private var brand: some View {
        Text("クレーン試験対策").font(.headline).foregroundColor(Theme.fg).fixedSize(horizontal: false, vertical: true)
    }
    private var dateLabel: String {
        guard examEpoch > 0 else { return "試験日を設定" }
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: Date()),
                                      to: cal.startOfDay(for: Date(timeIntervalSince1970: examEpoch))).day ?? 0
        return days > 0 ? "試験まで \(days)日" : days == 0 ? "今日は試験日" : "試験日を変更"
    }
    private var dateButton: some View {
        Button { showDate = true } label: {
            Label(dateLabel, systemImage: "calendar").font(.caption.weight(.semibold))
                .foregroundColor(Theme.muted).padding(.horizontal, 10).frame(minHeight: 44)
                .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain)
    }

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            if let hero {
                GeometryReader { geo in
                    HomeHeroArtwork(hero: hero).frame(width: geo.size.width, height: geo.size.height).clipped()
                }
                LinearGradient(colors: [.black.opacity(0.05), .black.opacity(0.70)], startPoint: .top, endPoint: .bottom)
            } else { Theme.card2 }
            Text("今日の一歩が、\n現場の自信になる。")
                .font(.title2.bold()).foregroundColor(hero == nil ? Theme.fg : .white)
                .fixedSize(horizontal: false, vertical: true).padding(18).padding(.top, 52)
        }
        .frame(minHeight: typeSize.isAccessibilitySize ? 310 : (hero == nil ? 145 : 180))
        .overlay(alignment: .topTrailing) {
            Button { showHeroPicker = true } label: {
                Label("背景を選ぶ", systemImage: "photo").font(.caption.weight(.semibold))
                    .foregroundColor(hero == nil ? Theme.fg : .white)
                    .padding(.horizontal, 12).frame(minHeight: 44)
                    .background(hero == nil ? Theme.card : Color.black.opacity(0.48)).clipShape(Capsule())
            }.buttonStyle(.plain).padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var resumeCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(store.lastStudyPlace == nil ? "はじめの一歩" : "前回の学習")
                .font(.subheadline.bold()).foregroundColor(HomeStyle.teal)
            HStack(spacing: 12) {
                Image(systemName: nextPlace?.kind.symbol ?? "book").font(.title2).foregroundColor(HomeStyle.teal)
                    .frame(width: 42, height: 44).background(HomeStyle.tealFill).clipShape(RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 4) {
                    if let chapter = nextPlace?.chapterID {
                        Text("第\(chapter)章 · \(nextPlace?.kind.label ?? "教材")").font(.caption).foregroundColor(Theme.muted)
                    }
                    Text(nextPlace?.title ?? "教材で学ぶ").font(.headline).foregroundColor(Theme.fg)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            primary(resumeLabel, action: resumeStudy)
        }.homePanel()
    }
    private var resumeLabel: String {
        if nextPlace?.kind == .exam { return "模試を開く" }
        return store.lastStudyPlace == nil ? "学習をはじめる" : "つづきから学ぶ"
    }
    private func resumeStudy() {
        welcomeSeen = true
        guard let place = nextPlace else { router.tab = 1; return }
        switch place.kind {
        case .exam: router.tab = 2
        case .glossary where place.chapterID == nil: router.tab = 3
        default: resumePlace = place
        }
    }

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Label("無料ライセンス 有効", systemImage: "checkmark.seal")
                    .font(.subheadline.bold()).foregroundColor(HomeStyle.teal)
                Spacer(minLength: 0)
                Button { welcomeSeen = true } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }
                    .foregroundColor(Theme.muted).accessibilityLabel("無料利用の案内を閉じる")
            }
            Text("全機能を、期限なく無料で。")
                .font(.title2.bold()).foregroundColor(Theme.fg).fixedSize(horizontal: false, vertical: true)
            Text("あなたはキャンペーンの対象です。教材も模試も、期間を気にせず自分のペースで学習できます。")
                .font(.subheadline).foregroundColor(Theme.muted).fixedSize(horizontal: false, vertical: true)
            Text("教材 全4章・模試 全\(store.exams.count)回・用語集・相関図")
                .font(.subheadline.bold()).foregroundColor(HomeStyle.teal)
                .fixedSize(horizontal: false, vertical: true)
            primary(resumeLabel, action: resumeStudy)
        }.homePanel()
    }

    private var weekCard: some View {
        let week = store.studyActivity.week(legacyAnswers: store.dailyAnswers)
        let count = week.filter(\.studied).count
        let today = Calendar.current.startOfDay(for: Date())
        let labels = ["月", "火", "水", "木", "金", "土", "日"]
        let summary = StudyKind.allCases.compactMap { kind -> String? in
            let total = week.reduce(0) { $0 + ($1.counts[kind.rawValue] ?? 0) }
            return total > 0 ? "\(kind.label) \(total)回" : nil
        }.joined(separator: " ・ ")
        return VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline) {
                Text("今週の積み重ね").font(.headline).foregroundColor(Theme.fg)
                Spacer(minLength: 6)
                Text("\(count)日学習").font(.subheadline.bold()).foregroundColor(HomeStyle.teal)
            }
            HStack(spacing: 4) {
                ForEach(Array(week.enumerated()), id: \.element.id) { i, day in
                    VStack(spacing: 7) {
                        Text(labels[i]).font(.caption).foregroundColor(Theme.muted)
                        ZStack {
                            Circle().fill(day.studied ? HomeStyle.tealFill : Theme.card2)
                            if day.studied { Image(systemName: "checkmark").font(.caption.bold()).foregroundColor(HomeStyle.teal) }
                            else { Text("·").foregroundColor(Theme.muted) }
                        }.frame(width: 28, height: 28)
                            .overlay(Circle().stroke(day.date == today ? HomeStyle.teal : .clear, lineWidth: 1.5))
                    }.frame(maxWidth: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(labels[i])曜日、\(day.studied ? "学習しました" : day.date > today ? "これから" : "学習記録なし")")
                }
            }
            Text(!summary.isEmpty ? summary : count > 0 ? "これまでの模試の解答記録も含めています。" : "教材も、用語も、模試も。学んだ日を記録します。")
                .font(.footnote).foregroundColor(Theme.muted).fixedSize(horizontal: false, vertical: true)
        }.homePanel()
    }

    private func primary(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack { Text(title); Image(systemName: "chevron.right") }
                .font(.headline).foregroundColor(HomeStyle.ink).frame(maxWidth: .infinity, minHeight: 48)
                .padding(.vertical, 4).background(HomeStyle.gold).clipShape(RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain)
    }
    private func entry(_ symbol: String, _ title: String, _ subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: symbol).foregroundColor(HomeStyle.teal)
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundColor(Theme.muted)
                }
                Text(title).font(.headline).foregroundColor(Theme.fg)
                Text(subtitle).font(.caption).foregroundColor(Theme.muted).fixedSize(horizontal: false, vertical: true)
            }.frame(maxWidth: .infinity, alignment: .leading).homePanel()
        }.buttonStyle(.plain)
    }
    private var savedRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack { savedButtons }
            VStack(alignment: .leading) { savedButtons }
        }.font(.subheadline).foregroundColor(HomeStyle.teal).buttonStyle(.plain).homePanel()
    }
    @ViewBuilder private var savedButtons: some View {
        Button { showFavorites = true } label: { Label("お気に入りの用語", systemImage: "heart").frame(minHeight: 44) }
        Spacer(minLength: 8)
        Button { showBookmarks = true } label: { Label("ブックマーク", systemImage: "bookmark").frame(minHeight: 44) }
    }
    private func utility(_ title: String, subtitle: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.title2).foregroundColor(HomeStyle.teal)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.subheadline.bold()).foregroundColor(Theme.fg)
                    Text(subtitle).font(.caption).foregroundColor(Theme.muted)
                }.fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption).foregroundColor(Theme.muted)
            }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).homePanel()
        }.buttonStyle(.plain)
    }
}

private extension View {
    func homePanel() -> some View {
        self.padding(16).background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
    }
}

private struct HomeResumeSheet: View {
    let place: StudyPlace
    @EnvironmentObject private var store: ExamStore
    @EnvironmentObject private var purchases: PurchaseStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Group {
                if let chapter = store.textbook?.chapters.first(where: { $0.id == place.chapterID }) {
                    if place.kind == .glossary {
                        GlossaryChapterView(chapter: chapter).trackStudyCompletion(kind: .glossary)
                    } else if let index = chapter.sections.firstIndex(where: { $0.id == place.sectionID }),
                              purchases.isPro || index < 4 {
                        SectionPagerView(chapter: chapter, start: index)
                    } else { ChapterSectionsView(chapter: chapter) }
                } else { Text("教材一覧から学習を再開してください。").foregroundColor(Theme.muted) }
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("閉じる") { dismiss() } } }
        }
    }
}
