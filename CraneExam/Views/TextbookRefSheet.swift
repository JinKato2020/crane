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

    /// 固定IDを優先。古いデータでは小見出し・本文・表・箇条書きを検索する。
    private func anchorIndex(_ sec: TBSection) -> Int? {
        TextbookReferenceResolver.index(in: sec, for: ref)
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

                    if ai == nil && (ref.blockID != nil || ref.anchor?.isEmpty == false) {
                        Text("指定の箇所が見つからないため、この節の全体を表示しています。設定から教材を更新してください。")
                            .font(.system(size: 14)).foregroundColor(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ForEach(Array(section.blocks.enumerated()), id: \.offset) { i, b in
                        blockRow(i, b, highlighted: ai == i)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 32)
            }
            .task(id: "\(store.contentRevision)-\(ref.id)") {
                guard let target = ai else { return }
                // キャンセル可能にして、閉じたシート・古い教材への遅延移動を防ぐ。
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                proxy.scrollTo(target, anchor: .top)
            }
        }
    }

    @ViewBuilder
    private func blockRow(_ i: Int, _ b: TBBlock, highlighted: Bool) -> some View {
        if highlighted {
            BlockView(block: b)
                .id(i)
                .padding(10)
                .background(Theme.gold.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.gold.opacity(0.5), lineWidth: 1))
        } else {
            BlockView(block: b).id(i)
        }
    }
}
