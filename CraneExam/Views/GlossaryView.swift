import SwiftUI
import UIKit

/// 全4章の重要用語集（学科タブ「用語」に埋め込んで表示）。
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

    private func tbUIImage(_ name: String) -> UIImage? {
        guard let path = (Bundle.main.path(forResource: name, ofType: "jpg") ?? Bundle.main.path(forResource: name, ofType: "png")) else { return nil }
        return UIImage(contentsOfFile: path)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // 検索
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").font(.system(size: 14)).foregroundColor(Theme.faint)
                TextField("用語を検索", text: $query)
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

            if query.isEmpty {
                Text("全\(totalCount)語を収録").font(.system(size: 12)).foregroundColor(Theme.faint)
                    .padding(.leading, 2).padding(.top, -4)
            }

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
                        VStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.offset) { i, t in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(t.term).font(.system(size: 14, weight: .bold)).foregroundColor(Theme.accent2)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(t.def).font(.system(size: 12.5)).foregroundColor(Theme.muted)
                                        .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                                    if let name = t.img, let ui = tbUIImage(name) {
                                        Image(uiImage: ui).resizable().scaledToFit()
                                            .frame(maxWidth: .infinity, maxHeight: 120, alignment: .leading)
                                            .background(Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 9))
                                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(Theme.line, lineWidth: 1))
                                            .padding(.top, 6)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 15).padding(.vertical, 13)
                                .background(i % 2 == 0 ? Theme.card : Theme.card2)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.line, lineWidth: 1))
                    }
                }
            }

            if chapters.allSatisfy({ terms($0).isEmpty }) {
                VStack(spacing: 11) {
                    Image(systemName: "character.book.closed").font(.system(size: 38)).foregroundColor(Theme.faint)
                    Text(query.isEmpty ? "用語データを読み込めませんでした。" : "「\(query)」に一致する用語はありません。")
                        .font(.system(size: 13)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 54)
            }
        }
    }
}
