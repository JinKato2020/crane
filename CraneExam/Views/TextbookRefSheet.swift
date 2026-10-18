import SwiftUI

/// 解説に置く「テキストで確認」ボタン（問題に関連する教材へのピンポイント直リンク）。
struct TextRefButton: View {
    let ref: TextRef
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: "book.fill").font(.system(size: 12, weight: .bold))
                Text("テキストで確認" + (ref.label.map { "（\($0)）" } ?? ""))
                    .font(.system(size: 13, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                Image(systemName: "arrow.up.forward").font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(Theme.accent2)
            .padding(.vertical, 10).padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.accent2.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.accent2.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// 「テキストで確認」で開く、教材の該当箇所シート。
/// 指定の節を表示し、anchor（小見出しキーワード）があればそこへスクロール＋ハイライト。
/// 上部に常に「問題に戻る」を置くので、閉じれば必ず元の問題に戻れる（別タブへ移動して迷子にならない）。
struct TextbookRefSheet: View {
    @EnvironmentObject var store: ExamStore
    @Environment(\.dismiss) private var dismiss
    let ref: TextRef

    /// section ID から（章, 節）を探す
    private var found: (chapter: TBChapter, section: TBSection)? {
        guard let chs = store.textbook?.chapters else { return nil }
        for ch in chs {
            if let s = ch.sections.first(where: { $0.id == ref.section }) { return (ch, s) }
        }
        return nil
    }

    /// anchor に一致する最初のブロックの位置（小見出し優先、無ければ本文）
    private func anchorIndex(_ sec: TBSection) -> Int? {
        guard let a = ref.anchor, !a.isEmpty else { return nil }
        if let i = sec.blocks.firstIndex(where: { $0.type == "sub" && ($0.text ?? "").contains(a) }) { return i }
        return sec.blocks.firstIndex(where: { ($0.text ?? "").contains(a) })
    }

    var body: some View {
        NavigationStack {
            Group {
                if let f = found {
                    sectionBody(f.chapter, f.section)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "book.closed").font(.system(size: 34)).foregroundColor(Theme.faint)
                        Text("該当する教材が見つかりませんでした")
                            .font(.system(size: 13)).foregroundColor(Theme.muted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("テキストで確認")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("問題に戻る")
                        }
                        .font(.system(size: 15, weight: .bold))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sectionBody(_ chapter: TBChapter, _ section: TBSection) -> some View {
        let ai = anchorIndex(section)
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("第\(chapter.id)章").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.accent2)
                        Text(section.title).font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.fg)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, 12)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(Theme.gold).frame(width: 4, height: 24)
                    }
                    .padding(.top, 10)

                    ForEach(Array(section.blocks.enumerated()), id: \.offset) { i, b in
                        blockRow(i, b, highlighted: ai == i)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 32)
            }
            .onAppear {
                guard let target = ai else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.4)) { proxy.scrollTo(target, anchor: .top) }
                }
            }
        }
    }

    @ViewBuilder
    private func blockRow(_ i: Int, _ b: TBBlock, highlighted: Bool) -> some View {
        BlockView(block: b)
            .id(i)
            .padding(highlighted ? 10 : 0)
            .background(highlighted ? Theme.gold.opacity(0.16) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                if highlighted {
                    RoundedRectangle(cornerRadius: 10).stroke(Theme.gold.opacity(0.5), lineWidth: 1)
                }
            }
    }
}
