import SwiftUI

/// 全4章の重要用語を集めた用語集(ホームの専用カードから開く)
struct GlossaryView: View {
    @EnvironmentObject var store: ExamStore
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    private var chapters: [TBChapter] { store.textbook?.chapters ?? [] }

    private func terms(_ ch: TBChapter) -> [TBTerm] {
        let all = ch.glossary ?? []
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return all }
        return all.filter { $0.term.localizedCaseInsensitiveContains(q) || $0.def.localizedCaseInsensitiveContains(q) }
    }

    private var totalCount: Int { chapters.reduce(0) { $0 + ($1.glossary?.count ?? 0) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 検索
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").font(.system(size: 13)).foregroundColor(Theme.faint)
                        TextField("用語を検索", text: $query)
                            .font(.system(size: 14)).foregroundColor(Theme.fg)
                            .autocorrectionDisabled(true)
                        if !query.isEmpty {
                            Button { query = "" } label: {
                                Image(systemName: "xmark.circle.fill").font(.system(size: 14)).foregroundColor(Theme.faint)
                            }
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1))

                    ForEach(chapters) { ch in
                        let items = terms(ch)
                        if !items.isEmpty {
                            VStack(alignment: .leading, spacing: 9) {
                                HStack(spacing: 8) {
                                    Text("第\(ch.id)章").font(.system(size: 11, weight: .bold)).foregroundColor(Color(hex: 0x241703))
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(Theme.gold).clipShape(Capsule())
                                    Text(ch.title).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.fg)
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(items.count)語").font(.system(size: 11)).foregroundColor(Theme.muted)
                                }
                                VStack(spacing: 0) {
                                    ForEach(Array(items.enumerated()), id: \.offset) { i, t in
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(t.term).font(.system(size: 13.5, weight: .bold)).foregroundColor(Theme.accent2)
                                                .fixedSize(horizontal: false, vertical: true)
                                            Text(t.def).font(.system(size: 12.5)).foregroundColor(Theme.muted)
                                                .lineSpacing(2).fixedSize(horizontal: false, vertical: true)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 12).padding(.vertical, 9)
                                        .background(i % 2 == 0 ? Theme.card : Theme.card2)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1))
                            }
                        }
                    }

                    if chapters.allSatisfy({ terms($0).isEmpty }) {
                        VStack(spacing: 10) {
                            Image(systemName: "character.book.closed").font(.system(size: 36)).foregroundColor(Theme.faint)
                            Text(query.isEmpty ? "用語データを読み込めませんでした。" : "「\(query)」に一致する用語はありません。")
                                .font(.system(size: 13)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 50)
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("用語集(全\(totalCount)語)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }.foregroundColor(Theme.accent)
                }
            }
        }
    }
}
