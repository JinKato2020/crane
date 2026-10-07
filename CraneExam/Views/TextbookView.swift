import SwiftUI
import UIKit

/// 「学科」タブ内の教材(章一覧)
struct TextbookListView: View {
    @EnvironmentObject var store: ExamStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let chapters = store.textbook?.chapters, !chapters.isEmpty {
                ForEach(chapters) { ch in
                    NavigationLink {
                        ChapterSectionsView(chapter: ch)
                    } label: {
                        chapterRow(ch)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("教材データを読み込めませんでした。")
                    .foregroundColor(Theme.muted).font(.system(size: 13)).padding()
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
                Text("全\(ch.sections.count)節").font(.system(size: 11)).foregroundColor(Theme.faint)
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
}

/// 章を選んだ後の「節の選択画面」
struct ChapterSectionsView: View {
    let chapter: TBChapter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 章タイトル
                VStack(alignment: .leading, spacing: 6) {
                    Text("第\(chapter.id)章").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.accent2)
                    Text(chapter.title).font(.system(size: 21, weight: .heavy)).foregroundColor(Theme.fg)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(chapter.summary).font(.system(size: 12)).foregroundColor(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4).padding(.bottom, 2)

                HStack {
                    Text("節を選ぶ").font(.system(size: 13, weight: .heavy)).foregroundColor(Theme.fg)
                    Spacer()
                    Text("全\(chapter.sections.count)節").font(.system(size: 11)).foregroundColor(Theme.muted)
                }
                .padding(.bottom, 1)

                ForEach(Array(chapter.sections.enumerated()), id: \.element.id) { idx, sec in
                    NavigationLink {
                        SectionPagerView(chapter: chapter, start: idx)
                    } label: {
                        sectionRow(number: idx + 1, title: sec.title)
                    }
                    .buttonStyle(.plain)
                }

                Text("節を開くと、左右スワイプで前後の節へ移動できます。")
                    .font(.system(size: 11.5)).foregroundColor(Theme.faint)
                    .padding(.horizontal, 2).padding(.top, 2)
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("第\(chapter.id)章")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionRow(number: Int, title: String) -> some View {
        HStack(spacing: 13) {
            Text("\(number)")
                .font(.system(size: 17, weight: .bold, design: .rounded)).foregroundColor(Theme.accent2)
                .frame(width: 40, height: 40)
                .background(Theme.raise).clipShape(RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.line, lineWidth: 1))
            Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(Theme.fg)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.faint)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
    }
}

/// 1節を表示し、左右スワイプで前後の節へ移動できるビュー
struct SectionPagerView: View {
    let chapter: TBChapter
    @State private var index: Int

    init(chapter: TBChapter, start: Int) {
        self.chapter = chapter
        _index = State(initialValue: start)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 進捗ヘッダー
            HStack(spacing: 10) {
                Button {
                    if index > 0 { withAnimation { index -= 1 } }
                } label: {
                    Image(systemName: "chevron.left").font(.system(size: 14, weight: .bold))
                }
                .disabled(index == 0).foregroundColor(index == 0 ? Theme.faint : Theme.accent2)

                Spacer()
                Text("\(index + 1) / \(chapter.sections.count) 節")
                    .font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted)
                Spacer()

                Button {
                    if index < chapter.sections.count - 1 { withAnimation { index += 1 } }
                } label: {
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold))
                }
                .disabled(index == chapter.sections.count - 1)
                .foregroundColor(index == chapter.sections.count - 1 ? Theme.faint : Theme.accent2)
            }
            .padding(.horizontal, 16).padding(.vertical, 9)
            .background(Theme.raise)
            .overlay(alignment: .bottom) { Rectangle().fill(Theme.line).frame(height: 1) }

            // 節本文(ページ=スワイプ移動)
            TabView(selection: $index) {
                ForEach(Array(chapter.sections.enumerated()), id: \.offset) { i, sec in
                    SectionContentView(section: sec,
                                       position: i + 1,
                                       total: chapter.sections.count)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: index)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("第\(chapter.id)章")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 1節ぶんの本文(スクロール)
struct SectionContentView: View {
    let section: TBSection
    let position: Int
    let total: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(section.title)
                    .font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.fg)
                    .padding(.leading, 10)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(Theme.gold).frame(width: 4, height: 20)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)

                ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, b in
                    BlockView(block: b)
                }

                HStack(spacing: 6) {
                    Image(systemName: "hand.draw").font(.system(size: 11)).foregroundColor(Theme.faint)
                    Text(position < total ? "スワイプで次の節へ" : "この章の最後の節です")
                        .font(.system(size: 11)).foregroundColor(Theme.faint)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
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
                        .overlay(
                            GeometryReader { g in
                                ForEach(Array((block.labels ?? []).enumerated()), id: \.offset) { _, lb in
                                    Text(lb.text)
                                        .font(.system(size: 8.5, weight: .bold))
                                        .padding(.horizontal, 3).padding(.vertical, 1)
                                        .background(RoundedRectangle(cornerRadius: 3).fill(Color.black.opacity(0.66)))
                                        .foregroundColor(.white)
                                        .fixedSize()
                                        .position(x: lb.x * g.size.width, y: lb.y * g.size.height)
                                }
                            }
                        )
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
                if let leg = block.legend, !leg.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(leg.enumerated()), id: \.offset) { _, s in
                            Text("・" + s).font(.system(size: 11)).foregroundColor(Theme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.top, 1)
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
