import SwiftUI
import UIKit

/// 「学科」タブ内の教材(章一覧)
struct TextbookListView: View {
    @EnvironmentObject var store: ExamStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHead(title: "教材で学ぶ(全4章)", trailing: "読んで理解")
            if let chapters = store.textbook?.chapters, !chapters.isEmpty {
                ForEach(chapters) { ch in
                    NavigationLink {
                        ChapterReaderView(chapter: ch)
                    } label: {
                        chapterRow(ch)
                    }
                    .buttonStyle(.plain)
                }
                Text("図表と用語集つきで、試験範囲をやさしく解説します。")
                    .font(.system(size: 11.5)).foregroundColor(Theme.faint)
                    .padding(.horizontal, 2).padding(.top, 2)
            } else {
                Text("教材データを読み込めませんでした。")
                    .foregroundColor(Theme.muted).font(.system(size: 13)).padding()
            }
        }
    }

    private func chapterRow(_ ch: TBChapter) -> some View {
        HStack(spacing: 13) {
            VStack(spacing: 1) {
                Text("\(ch.id)").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(Theme.accent2)
                Text("第\(ch.id)章").font(.system(size: 8.5)).foregroundColor(Theme.muted)
            }
            .frame(width: 46, height: 46)
            .background(Theme.raise).clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text(ch.title).font(.system(size: 14, weight: .bold)).foregroundColor(Theme.fg)
                    .fixedSize(horizontal: false, vertical: true)
                Text(ch.summary).font(.system(size: 11)).foregroundColor(Theme.muted)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 6)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.faint)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
    }
}

/// 1章を読むビュー
struct ChapterReaderView: View {
    let chapter: TBChapter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // 章タイトル
                VStack(alignment: .leading, spacing: 6) {
                    Text("第\(chapter.id)章").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.accent2)
                    Text(chapter.title).font(.system(size: 21, weight: .heavy)).foregroundColor(Theme.fg)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(chapter.summary).font(.system(size: 12)).foregroundColor(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)

                ForEach(chapter.sections) { sec in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(sec.title)
                            .font(.system(size: 16, weight: .bold)).foregroundColor(Theme.fg)
                            .padding(.leading, 10)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2).fill(Theme.gold).frame(width: 4, height: 18)
                            }
                        ForEach(Array(sec.blocks.enumerated()), id: \.offset) { _, b in
                            BlockView(block: b)
                        }
                    }
                    .padding(.bottom, 2)
                }

                Text("© クレーン試験対策 教材")
                    .font(.system(size: 10)).foregroundColor(Theme.faint)
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("第\(chapter.id)章")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 1ブロックを描画
struct BlockView: View {
    let block: TBBlock

    var body: some View {
        switch block.type {
        case "sub":
            Text(md(block.text))
                .font(.system(size: 14, weight: .bold)).foregroundColor(Theme.accent2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)

        case "p":
            Text(md(block.text))
                .font(.system(size: 13.5)).foregroundColor(Theme.fg)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

        case "ul":
            VStack(alignment: .leading, spacing: 7) {
                ForEach(Array((block.items ?? []).enumerated()), id: \.offset) { _, s in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(Theme.accent).frame(width: 5, height: 5).padding(.top, 7)
                        Text(md(s)).font(.system(size: 13.5)).foregroundColor(Theme.fg)
                            .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

        case "fig":
            ScrollView(.horizontal, showsIndicators: false) {
                Text(block.text ?? "")
                    .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.fg)
                    .padding(12)
            }
            .background(Theme.card2)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1))

        case "img":
            VStack(alignment: .leading, spacing: 6) {
                if let name = block.asset,
                   let path = (Bundle.main.path(forResource: name, ofType: "jpg") ?? Bundle.main.path(forResource: name, ofType: "png")),
                   let ui = UIImage(contentsOfFile: path) {
                    Image(uiImage: ui).resizable().scaledToFit()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1))
                } else {
                    RoundedRectangle(cornerRadius: 10).fill(Theme.card2)
                        .frame(height: 120)
                        .overlay(
                            VStack(spacing: 6) {
                                Image(systemName: "photo").font(.system(size: 24)).foregroundColor(Theme.faint)
                                Text("図は準備中").font(.system(size: 11)).foregroundColor(Theme.faint)
                            }
                        )
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, style: StrokeStyle(lineWidth: 1, dash: [4])))
                }
                if let cap = block.caption, !cap.isEmpty {
                    Text("図：" + cap).font(.system(size: 11.5)).foregroundColor(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

        case "table":
            TableBlock(headers: block.headers ?? [], rows: block.rows ?? [])

        case "point":
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill").font(.system(size: 12)).foregroundColor(Theme.accent)
                    Text("ここが出る").font(.system(size: 13, weight: .heavy)).foregroundColor(Theme.accent)
                }
                ForEach(Array((block.items ?? []).enumerated()), id: \.offset) { _, s in
                    HStack(alignment: .top, spacing: 8) {
                        Text("▶").font(.system(size: 9)).foregroundColor(Theme.accent).padding(.top, 4)
                        Text(md(s)).font(.system(size: 13, weight: .medium)).foregroundColor(Theme.fg)
                            .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.accent.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.accent.opacity(0.35), lineWidth: 1))

        default:
            EmptyView()
        }
    }

    /// Markdownの**太字**を解釈(失敗時はそのまま)
    private func md(_ s: String?) -> AttributedString {
        let raw = s ?? ""
        if let a = try? AttributedString(markdown: raw) { return a }
        return AttributedString(raw)
    }
}

/// 表の描画(2列はキー/値、3列以上は行カード)
struct TableBlock: View {
    let headers: [String]
    let rows: [[String]]

    var body: some View {
        if headers.count <= 2 {
            VStack(spacing: 0) {
                if !headers.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        Text(headers[0]).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.muted)
                            .frame(width: 104, alignment: .leading)
                        if headers.count > 1 {
                            Text(headers[1]).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.muted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Theme.raise)
                }
                ForEach(Array(rows.enumerated()), id: \.offset) { i, r in
                    HStack(alignment: .top, spacing: 10) {
                        Text(attr(r.first ?? "")).font(.system(size: 12.5, weight: .semibold)).foregroundColor(Theme.fg)
                            .frame(width: 104, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                        if r.count > 1 {
                            Text(attr(r[1])).font(.system(size: 12.5)).foregroundColor(Theme.muted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(i % 2 == 0 ? Theme.card : Theme.card2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1))
        } else {
            // 3列以上: 1行=1カード
            VStack(spacing: 8) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, r in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(attr(r.first ?? "")).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.fg)
                            .fixedSize(horizontal: false, vertical: true)
                        ForEach(1..<max(1, r.count), id: \.self) { j in
                            if j < headers.count {
                                HStack(alignment: .top, spacing: 6) {
                                    Text(headers[j]).font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.accent2)
                                        .frame(width: 58, alignment: .leading)
                                    Text(attr(r[j])).font(.system(size: 12.5)).foregroundColor(Theme.muted)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding(11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1))
                }
            }
        }
    }

    private func attr(_ s: String) -> AttributedString {
        if let a = try? AttributedString(markdown: s) { return a }
        return AttributedString(s)
    }
}
