import SwiftUI

/// Shared glossary presentation. Favorite IDs remain the original `term` strings.
struct GlossaryView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("用語で確かめる").font(.title2.bold()).foregroundColor(Theme.fg)
                        Text("まずひとことで理解。図・ポイントを開いて、違いや数字を確かめましょう。")
                            .font(.subheadline).foregroundColor(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    GlossaryContent()
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("用語")
            .navigationBarTitleDisplayMode(.inline)
        }
        .trackStudyCompletion(kind: .glossary)
    }
}

private struct GlossaryRichText: View {
    let value: String
    var body: some View {
        Text((try? AttributedString(markdown: value, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(value))
            .font(.body).foregroundColor(Theme.fg).lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
    }
}

private struct GlossarySearchField: View {
    @Binding var query: String
    let prompt: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundColor(Theme.muted).accessibilityHidden(true)
            TextField(prompt, text: $query)
                .font(.body).foregroundColor(Theme.fg)
                .autocorrectionDisabled(true).textInputAutocapitalization(.never)
                .submitLabel(.search).accessibilityLabel(prompt)
                .frame(minHeight: 44)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(Theme.muted)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain).accessibilityLabel("検索を消去")
            }
        }
        .padding(.leading, 14).padding(.trailing, query.isEmpty ? 14 : 2).padding(.vertical, 4)
        .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 1))
    }
}

private struct GlossaryTermCard: View {
    @EnvironmentObject private var store: ExamStore
    let term: TBTerm
    var locked = false
    var onLockedTap: (() -> Void)?
    @State private var expanded = false
    @State private var selectedReference: TextRef?

    var body: some View {
        Group {
            if locked {
                Button { onLockedTap?() } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lock.fill").foregroundColor(Theme.studyKey)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(term.title).font(.headline).foregroundColor(Theme.fg)
                            Text("この用語は Pro で解放").font(.subheadline).foregroundColor(Theme.muted)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").foregroundColor(Theme.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(16)
                }
                .buttonStyle(.plain)
            } else {
                contents
            }
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
        .sheet(item: $selectedReference) { ref in
            TextbookRefSheet(ref: ref, closeLabel: "用語に戻る")
        }
    }

    private var contents: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 6) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(term.title).font(.headline).foregroundColor(Theme.fg)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if let reading = term.reading {
                        Text(reading).font(.caption).foregroundColor(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button { store.toggleFavTerm(term.id) } label: {
                    Image(systemName: store.isFavTerm(term.id) ? "heart.fill" : "heart")
                        .font(.title3).foregroundColor(store.isFavTerm(term.id) ? Theme.studyKey : Theme.muted)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(term.title)をお気に入り\(store.isFavTerm(term.id) ? "から解除" : "に追加")")
            }
            GlossaryRichText(value: term.introduction)
            if term.hasDetails {
                Button { expanded.toggle() } label: {
                    HStack(spacing: 9) {
                        Image(systemName: expanded ? "chevron.up" : (term.illustrations.isEmpty ? "text.alignleft" : "photo"))
                        Text(expanded ? "ポイントを閉じる" : (term.illustrations.isEmpty ? "ポイントを見る" : "図・ポイントを見る"))
                            .font(.subheadline.weight(.semibold))
                        Spacer(minLength: 0)
                        if !expanded { Image(systemName: "chevron.down") }
                    }
                    .foregroundColor(Theme.studyKey).frame(minHeight: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(expanded ? "展開中" : "折りたたみ中")
                .accessibilityHint("\(term.title)の詳しい説明を\(expanded ? "閉じます" : "開きます")")
            }
            if expanded { details }
        }
        .padding(16)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 20) {
            Rectangle().fill(Theme.line).frame(height: 1).accessibilityHidden(true)
            if let points = term.points, !points.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    Text("覚えるポイント").font(.subheadline.bold()).foregroundColor(Theme.studyKey)
                    ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                        HStack(alignment: .top, spacing: 10) {
                            Text("•").font(.body.bold()).foregroundColor(Theme.studyKey).accessibilityHidden(true)
                            GlossaryRichText(value: point)
                        }
                    }
                }
            }
            if let example = term.example {
                VStack(alignment: .leading, spacing: 8) {
                    Label("例でつかむ", systemImage: "lightbulb").font(.subheadline.bold()).foregroundColor(Theme.studyKey)
                    GlossaryRichText(value: example)
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(14)
                .background(Theme.studyKey.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            if let comparison = term.comparison {
                GlossaryComparisonView(comparison: comparison)
            }
            if !term.illustrations.isEmpty {
                VStack(alignment: .leading, spacing: 18) {
                    Label("図で確かめる · タップで拡大", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.subheadline.weight(.semibold)).foregroundColor(Theme.muted)
                    ForEach(term.illustrations) { figure in
                        VStack(alignment: .leading, spacing: 10) {
                            if figure.isSVG {
                                SVGFigureView(file: figure.file, caption: figure.caption, thumbMaxHeight: 480)
                            } else {
                                let info = store.figureInfo[figure.assetName]
                                FigureImageView(assetName: figure.assetName,
                                                labels: info?.labels ?? [], legend: info?.legend ?? [],
                                                caption: figure.caption ?? term.title, thumbMaxHeight: 480, showLegend: false)
                            }
                            if let caption = figure.caption, !caption.isEmpty {
                                Text(caption).font(.subheadline).foregroundColor(Theme.muted)
                                    .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            if let refs = term.references, !refs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(refs) { ref in
                        Button { selectedReference = ref } label: {
                            HStack(alignment: .center, spacing: 10) {
                                Image(systemName: "book")
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("教材で詳しく").font(.subheadline.bold())
                                    Text(ref.label ?? term.title).font(.subheadline)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(Theme.studyKey).frame(minHeight: 44)
                            .padding(12).background(Theme.raise).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct GlossaryComparisonView: View {
    @Environment(\.dynamicTypeSize) private var textSize
    let comparison: TBTermComparison
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(comparison.title).font(.subheadline.bold()).foregroundColor(Theme.studyKey)
            VStack(spacing: 0) {
                if textSize < .xxxLarge {
                    row(comparison.headers, header: true)
                        .background(Theme.raise)
                }
                ForEach(Array(comparison.rows.enumerated()), id: \.offset) { index, cells in
                    Rectangle().fill(Theme.line).frame(height: 1).accessibilityHidden(true)
                    Group {
                        if textSize >= .xxxLarge {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(Array(cells.enumerated()), id: \.offset) { column, cell in
                                    VStack(alignment: .leading, spacing: 4) {
                                        if comparison.headers.indices.contains(column) {
                                            Text(comparison.headers[column]).font(.subheadline)
                                                .foregroundColor(Theme.muted)
                                        }
                                        Text(cell).font(.body.weight(.semibold)).foregroundColor(Theme.fg)
                                    }
                                    .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                            .accessibilityElement(children: .combine)
                        } else {
                            row(cells, header: false)
                        }
                    }
                        .background(index.isMultiple(of: 2) ? Theme.card : Theme.card2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
        }
    }
    private func row(_ cells: [String], header: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                Text(cell).font(header ? .subheadline.weight(.semibold) : .body)
                    .foregroundColor(Theme.fg)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12).accessibilityElement(children: .combine)
    }
}

private struct GlossaryTermList: View {
    let items: [TBTerm]
    var lockedIDs: Set<String> = []
    var onLockedTap: (() -> Void)?
    var body: some View {
        LazyVStack(spacing: 14) {
            ForEach(items) { term in
                GlossaryTermCard(term: term, locked: lockedIDs.contains(term.id), onLockedTap: onLockedTap)
            }
        }
    }
}

private struct GlossaryEmptyResults: View {
    var reset: () -> Void
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass").font(.largeTitle).foregroundColor(Theme.muted).accessibilityHidden(true)
            Text("一致する用語がありません").font(.headline).foregroundColor(Theme.fg)
            Text("読み仮名や短い言葉でも検索できます。分野の絞り込みも確認してください。")
                .font(.body).foregroundColor(Theme.muted).multilineTextAlignment(.center)
            Button("検索・絞り込みをリセット", action: reset)
                .font(.body.weight(.semibold)).foregroundColor(Theme.studyKey).frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 32)
    }
}

private struct GlossaryChapterHeading: View {
    let chapter: TBChapter
    let count: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("第\(chapter.id)章 · \(count)項目").font(.subheadline.bold()).foregroundColor(Theme.studyKey)
            Text(chapter.title).font(.headline).foregroundColor(Theme.fg)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine).accessibilityAddTraits(.isHeader)
    }
}

struct GlossaryContent: View {
    @EnvironmentObject private var store: ExamStore
    @EnvironmentObject private var purchases: PurchaseStore
    @State private var query = ""
    @State private var showPaywall = false
    private var chapters: [TBChapter] { store.textbook?.chapters ?? [] }
    private var searching: Bool { !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var totalCount: Int { chapters.reduce(0) { $0 + ($1.glossary?.count ?? 0) } }
    private func terms(_ chapter: TBChapter) -> [TBTerm] { (chapter.glossary ?? []).filter { $0.matches(query) } }
    private func locked(_ items: [TBTerm]) -> Set<String> {
        purchases.isPro ? [] : Set(items.map(\.id)).subtracting(store.freeGlossaryTermIDs)
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            GlossarySearchField(query: $query, prompt: "全章から検索・読み仮名もOK")
            if searching {
                Text("検索結果 \(chapters.reduce(0) { $0 + terms($1).count })項目")
                    .font(.subheadline).foregroundColor(Theme.muted)
                ForEach(chapters) { chapter in
                    let items = terms(chapter)
                    if !items.isEmpty {
                        GlossaryChapterHeading(chapter: chapter, count: items.count)
                        GlossaryTermList(items: items, lockedIDs: locked(items), onLockedTap: { showPaywall = true })
                    }
                }
                if chapters.allSatisfy({ terms($0).isEmpty }) {
                    GlossaryEmptyResults { query = "" }
                }
            } else {
                NavigationLink { FavoriteTermsView() } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "heart.fill").foregroundColor(Theme.studyKey).font(.title2)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("お気に入りの用語").font(.headline).foregroundColor(Theme.fg)
                            Text("繰り返し確かめたい用語を集める · \(store.favoriteTerms().count)項目")
                                .font(.subheadline).foregroundColor(Theme.muted)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").foregroundColor(Theme.muted)
                    }
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                Text("章を選ぶ · 全\(totalCount)項目").font(.subheadline.bold()).foregroundColor(Theme.muted)
                if chapters.isEmpty {
                    Text("用語データを読み込めませんでした。設定から教材データを更新してください。")
                        .font(.body).foregroundColor(Theme.muted)
                }
                ForEach(chapters) { chapter in
                    NavigationLink { GlossaryChapterView(chapter: chapter) } label: {
                        HStack(alignment: .top, spacing: 14) {
                            Text("\(chapter.id)").font(.title2.bold()).foregroundColor(Theme.studyKey)
                                .frame(width: 42, height: 44).background(Theme.raise).clipShape(RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 8) {
                                Text(chapter.title).font(.headline).foregroundColor(Theme.fg)
                                Text(chapter.summary).font(.subheadline).foregroundColor(Theme.muted)
                                Text("\(chapter.glossary?.count ?? 0)項目").font(.subheadline).foregroundColor(Theme.studyKey)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").foregroundColor(Theme.muted).padding(.top, 12)
                        }
                        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }
}

struct GlossaryChapterView: View {
    @EnvironmentObject private var store: ExamStore
    @EnvironmentObject private var purchases: PurchaseStore
    let chapter: TBChapter
    @State private var query = ""
    @State private var category = ""
    @State private var showPaywall = false
    // Follow OTA updates while this screen is open.
    private var current: TBChapter { store.textbook?.chapters.first(where: { $0.id == chapter.id }) ?? chapter }
    private var allItems: [TBTerm] { current.glossary ?? [] }
    private var categories: [String] {
        allItems.compactMap(\.category).reduce(into: [String]()) { result, item in
            if !result.contains(item) { result.append(item) }
        }
    }
    private var items: [TBTerm] {
        allItems.filter { (category.isEmpty || $0.category == category) && $0.matches(query) }
    }
    private var lockedIDs: Set<String> {
        purchases.isPro ? [] : Set(allItems.map(\.id)).subtracting(store.freeGlossaryTermIDs)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                GlossaryChapterHeading(chapter: current, count: allItems.count)
                GlossarySearchField(query: $query, prompt: "この章から検索")
                if !categories.isEmpty {
                    Menu {
                        Picker("分野", selection: $category) {
                            Text("すべての分野").tag("")
                            ForEach(categories, id: \.self) { Text($0).tag($0) }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(category.isEmpty ? "すべての分野" : category)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.down")
                        }
                        .font(.subheadline.weight(.semibold)).foregroundColor(Theme.studyKey)
                        .frame(minHeight: 44).padding(.horizontal, 14)
                        .background(Theme.raise).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel("分野の絞り込み")
                    .accessibilityValue(category.isEmpty ? "すべての分野" : category)
                }
                if !lockedIDs.isEmpty {
                    Text("無料プランでは各章の先頭10項目まで。残りは Pro で解放できます。")
                        .font(.subheadline).foregroundColor(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text("\(items.count)項目 · 図や詳しい説明はカードから")
                    .font(.subheadline).foregroundColor(Theme.muted)
                if items.isEmpty {
                    GlossaryEmptyResults { query = ""; category = "" }
                } else {
                    GlossaryTermList(items: items, lockedIDs: lockedIDs, onLockedTap: { showPaywall = true })
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .navigationTitle("第\(chapter.id)章 用語").navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.rememberStudy(StudyPlace(kind: .glossary, title: "第\(chapter.id)章の用語", chapterID: chapter.id))
        }
    }
}

struct FavoriteTermsView: View {
    @EnvironmentObject private var store: ExamStore
    @EnvironmentObject private var purchases: PurchaseStore
    @State private var query = ""
    @State private var showPaywall = false
    private var groups: [(chapter: TBChapter, terms: [TBTerm])] {
        let favorites = store.favoriteTerms().filter { $0.term.matches(query) }
        return (store.textbook?.chapters ?? []).compactMap { chapter in
            let items = favorites.filter { $0.chapter.id == chapter.id }.map(\.term)
            return items.isEmpty ? nil : (chapter, items)
        }
    }
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                if store.favoriteTerms().isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "heart").font(.largeTitle).foregroundColor(Theme.studyKey)
                        Text("お気に入りの用語はありません").font(.headline).foregroundColor(Theme.fg)
                        Text("用語カードのハートを押すと、ここに集まります。")
                            .font(.body).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 40)
                } else {
                    GlossarySearchField(query: $query, prompt: "お気に入りから検索")
                    ForEach(groups, id: \.chapter.id) { group in
                        GlossaryChapterHeading(chapter: group.chapter, count: group.terms.count)
                        GlossaryTermList(items: group.terms,
                                         lockedIDs: purchases.isPro ? [] : Set(group.terms.map(\.id)).subtracting(store.freeGlossaryTermIDs),
                                         onLockedTap: { showPaywall = true })
                    }
                    if groups.isEmpty { GlossaryEmptyResults { query = "" } }
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .navigationTitle("お気に入りの用語").navigationBarTitleDisplayMode(.inline)
    }
}

struct FavoriteTermsScreen: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            FavoriteTermsView()
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("閉じる") { dismiss() } } }
        }
    }
}
