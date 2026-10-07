import SwiftUI
import UIKit

/// 1用語のカード(用語集で共有)。図は教材のラベルを重ねて表示し、タップで全画面拡大。
private struct GlossaryTermCard: View {
    @EnvironmentObject var store: ExamStore
    let term: TBTerm
    let striped: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(term.term).font(.system(size: 14, weight: .bold)).foregroundColor(Theme.accent2)
                .fixedSize(horizontal: false, vertical: true)
            Text(term.def).font(.system(size: 12.5)).foregroundColor(Theme.muted)
                .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
            if let name = term.img {
                let info = store.figureInfo[name]
                FigureImageView(assetName: name,
                                labels: info?.labels ?? [],
                                legend: info?.legend ?? [],
                                caption: info?.caption ?? term.term,
                                thumbMaxHeight: 150,
                                showLegend: false)
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 15).padding(.vertical, 13)
        .background(striped ? Theme.card2 : Theme.card)
    }
}

/// 複数用語をひとまとめのカードにする
private struct GlossaryTermList: View {
    let items: [TBTerm]
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, t in
                GlossaryTermCard(term: t, striped: i % 2 == 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.line, lineWidth: 1))
    }
}

/// 全4章の重要用語集（学科タブ「用語」に埋め込み）。
/// 検索していないときは「章を選ぶ」一覧 → 章ごとの用語へ。検索中は全章横断のフラット結果。
struct GlossaryContent: View {
    @EnvironmentObject var store: ExamStore
    @State private var query: String = ""

    private var chapters: [TBChapter] { store.textbook?.chapters ?? [] }

    private func terms(_ ch: TBChapter) -> [TBTerm] {
        let all = ch.glossary ?? []
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return all }
        return all.filter { $0.term.localizedCaseInsensitiveContains(q) || $0.def.localizedCaseInsensitiveContains(q) }
    }

    private var totalCount: Int { chapters.reduce(0) { $0 + ($1.glossary?.count ?? 0) } }
    private var searching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 検索
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").font(.system(size: 14)).foregroundColor(Theme.faint)
                TextField("用語を検索（全章から）", text: $query)
                    .font(.system(size: 15)).foregroundColor(Theme.fg)
                    .autocorrectionDisabled(true)
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 15)).foregroundColor(Theme.faint)
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.line, lineWidth: 1))

            if searching {
                searchResults
            } else {
                chapterList
            }
        }
    }

    // 章を選ぶ一覧
    private var chapterList: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("章を選ぶ").font(.system(size: 13, weight: .heavy)).foregroundColor(Theme.fg)
                Spacer()
                Text("全\(totalCount)語").font(.system(size: 11)).foregroundColor(Theme.muted)
            }
            .padding(.bottom, -2)

            if chapters.isEmpty {
                Text("用語データを読み込めませんでした。")
                    .foregroundColor(Theme.muted).font(.system(size: 13)).padding()
            } else {
                ForEach(chapters) { ch in
                    NavigationLink {
                        GlossaryChapterView(chapter: ch)
                    } label: {
                        chapterRow(ch)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func chapterRow(_ ch: TBChapter) -> some View {
        HStack(spacing: 16) {
            VStack(spacing: 1) {
                Text("\(ch.id)").font(.system(size: 23, weight: .bold, design: .rounded)).foregroundColor(Theme.accent2)
                Text("章").font(.system(size: 9)).foregroundColor(Theme.muted)
            }
            .frame(width: 54, height: 54)
            .background(Theme.raise).clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 1))

            VStack(alignment: .leading, spacing: 5) {
                Text(ch.title).font(.system(size: 15.5, weight: .bold)).foregroundColor(Theme.fg)
                    .fixedSize(horizontal: false, vertical: true)
                Text(ch.summary).font(.system(size: 12)).foregroundColor(Theme.muted)
                    .lineLimit(2).lineSpacing(2).fixedSize(horizontal: false, vertical: true)
                Text("用語 \(ch.glossary?.count ?? 0)語").font(.system(size: 11)).foregroundColor(Theme.faint)
                    .padding(.top, 1)
            }
            Spacer(minLength: 6)
            Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundColor(Theme.faint)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
    }

    // 検索結果(全章横断)
    private var searchResults: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(chapters) { ch in
                let items = terms(ch)
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 11) {
                        HStack(spacing: 9) {
                            Text("第\(ch.id)章").font(.system(size: 11, weight: .bold)).foregroundColor(Color(hex: 0x241703))
                                .padding(.horizontal, 9).padding(.vertical, 4)
                                .background(Theme.gold).clipShape(Capsule())
                            Text(ch.title).font(.system(size: 13.5, weight: .bold)).foregroundColor(Theme.fg)
                                .lineLimit(1)
                            Spacer()
                            Text("\(items.count)語").font(.system(size: 11)).foregroundColor(Theme.muted)
                        }
                        GlossaryTermList(items: items)
                    }
                }
            }

            if chapters.allSatisfy({ terms($0).isEmpty }) {
                VStack(spacing: 11) {
                    Image(systemName: "character.book.closed").font(.system(size: 38)).foregroundColor(Theme.faint)
                    Text("「\(query)」に一致する用語はありません。")
                        .font(.system(size: 13)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 54)
            }
        }
    }
}

/// 章を選んだ後の「その章の用語一覧」
struct GlossaryChapterView: View {
    let chapter: TBChapter
    @State private var query: String = ""

    private var allItems: [TBTerm] { chapter.glossary ?? [] }
    private var items: [TBTerm] {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return allItems }
        return allItems.filter { $0.term.localizedCaseInsensitiveContains(q) || $0.def.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // 章タイトル
                VStack(alignment: .leading, spacing: 6) {
                    Text("第\(chapter.id)章").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.accent2)
                    Text(chapter.title).font(.system(size: 21, weight: .heavy)).foregroundColor(Theme.fg)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("用語 全\(allItems.count)語").font(.system(size: 12)).foregroundColor(Theme.muted)
                }
                .padding(.top, 4).padding(.bottom, 2)

                // この章の中で検索
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").font(.system(size: 14)).foregroundColor(Theme.faint)
                    TextField("この章の用語を検索", text: $query)
                        .font(.system(size: 15)).foregroundColor(Theme.fg)
                        .autocorrectionDisabled(true)
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill").font(.system(size: 15)).foregroundColor(Theme.faint)
                        }
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))

                if items.isEmpty {
                    VStack(spacing: 11) {
                        Image(systemName: "character.book.closed").font(.system(size: 36)).foregroundColor(Theme.faint)
                        Text(allItems.isEmpty ? "この章の用語データがありません。" : "「\(query)」に一致する用語はありません。")
                            .font(.system(size: 13)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 48)
                } else {
                    GlossaryTermList(items: items)
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("第\(chapter.id)章 用語")
        .navigationBarTitleDisplayMode(.inline)
    }
}
