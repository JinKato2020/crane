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
    @EnvironmentObject private var store: ExamStore
    @EnvironmentObject private var purchases: PurchaseStore
    @State private var showPaywall = false
    private let freeSections = 4   // 無料は各章の先頭4節まで
    private let initialChapter: TBChapter

    init(chapter: TBChapter) { initialChapter = chapter }

    private var chapter: TBChapter {
        store.textbook?.chapters.first(where: { $0.id == initialChapter.id }) ?? initialChapter
    }

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
                    let locked = idx >= freeSections && !purchases.isPro
                    if locked {
                        Button { showPaywall = true } label: {
                            sectionRow(number: idx + 1, title: sec.title, locked: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink {
                            SectionPagerView(chapter: chapter, start: idx)
                        } label: {
                            sectionRow(number: idx + 1, title: sec.title, locked: false)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !purchases.isPro && chapter.sections.count > freeSections {
                    Text("無料プランでは各章の先頭\(freeSections)節まで読めます。\(freeSections + 1)節目以降は Pro で解放されます。")
                        .font(.system(size: 11.5)).foregroundColor(Theme.accent2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 2).padding(.top, 2)
                }
                Text("節を開くと、左右スワイプで前後の節へ移動できます。")
                    .font(.system(size: 11.5)).foregroundColor(Theme.faint)
                    .padding(.horizontal, 2).padding(.top, 2)
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .navigationTitle("第\(chapter.id)章")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionRow(number: Int, title: String, locked: Bool = false) -> some View {
        HStack(spacing: 13) {
            Text("\(number)")
                .font(.system(size: 17, weight: .bold, design: .rounded)).foregroundColor(Theme.accent2)
                .frame(width: 40, height: 40)
                .background(Theme.raise).clipShape(RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.line, lineWidth: 1))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(Theme.fg)
                    .fixedSize(horizontal: false, vertical: true)
                if locked {
                    Text("PRO で解放").font(.system(size: 10.5, weight: .heavy)).foregroundColor(Theme.accent2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: locked ? "lock.fill" : "chevron.right")
                .font(.system(size: 13, weight: .bold)).foregroundColor(locked ? Theme.accent2 : Theme.faint)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(locked ? Theme.accent2.opacity(0.3) : Theme.line, lineWidth: 1))
    }
}

/// 1節を表示し、左右スワイプで前後の節へ移動できるビュー
struct SectionPagerView: View {
    @EnvironmentObject private var store: ExamStore
    @EnvironmentObject private var purchases: PurchaseStore
    private let freeSections = 4   // 無料は各章の先頭4節まで
    private let initialChapter: TBChapter
    @State private var index: Int

    private var chapter: TBChapter {
        store.textbook?.chapters.first(where: { $0.id == initialChapter.id }) ?? initialChapter
    }

    /// 実際にページ送りできる節（無料は先頭4節まで）。
    private var secs: [TBSection] {
        let all = chapter.sections
        return purchases.isPro ? all : Array(all.prefix(freeSections))
    }

    init(chapter: TBChapter, start: Int) {
        initialChapter = chapter
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
                Text("\(index + 1) / \(secs.count) 節")
                    .font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted)
                Spacer()

                Button {
                    if index < secs.count - 1 { withAnimation { index += 1 } }
                } label: {
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold))
                }
                .disabled(index == secs.count - 1)
                .foregroundColor(index == secs.count - 1 ? Theme.faint : Theme.accent2)
            }
            .padding(.horizontal, 16).padding(.vertical, 9)
            .background(Theme.raise)
            .overlay(alignment: .bottom) { Rectangle().fill(Theme.line).frame(height: 1) }

            // 節本文(ページ=スワイプ移動)
            TabView(selection: $index) {
                ForEach(Array(secs.enumerated()), id: \.offset) { i, sec in
                    SectionContentView(section: sec,
                                       position: i + 1,
                                       total: secs.count)
                        .id("\(sec.id)-\(store.contentRevision)")
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: index)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("第\(chapter.id)章")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: secs.count) { count in
            index = min(index, max(0, count - 1))
        }
    }
}

/// 1節ぶんの本文(スクロール)
struct SectionContentView: View {
    let section: TBSection
    let position: Int
    let total: Int

    // 暗記クイズ（赤シート）：この節だけに効く状態
    @State private var quizOn = false
    @State private var quizSeed = 0
    @State private var quizCat = "all"
    @State private var answersVisible = false

    /// この節に {{ }} の印が1つでもあるか（あるときだけクイズのトグルを出す）
    private var hasMasks: Bool {
        section.blocks.contains { b in
            if !(b.quizTerms ?? []).isEmpty { return true }
            if MaskParser.hasMask(b.text) { return true }
            return (b.items ?? []).contains { MaskParser.hasMask($0) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(section.title)
                    .font(.system(size: 21, weight: .heavy)).foregroundColor(Theme.fg)
                    .lineSpacing(5)
                    .padding(.leading, 14)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(Theme.gold).frame(width: 4, height: 26)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10).padding(.bottom, 2)

                if hasMasks { quizBar }

                ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, b in
                    BlockView(block: b)
                }

                HStack(spacing: 6) {
                    Image(systemName: "hand.draw").font(.system(size: 11)).foregroundColor(Theme.faint)
                    Text(position < total ? "スワイプで次の節へ" : "この章の最後の節です")
                        .font(.system(size: 11)).foregroundColor(Theme.faint)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 20)
            }
            .padding(.horizontal, 24).padding(.vertical, 22)
        }
        .background(Theme.bg.ignoresSafeArea())
        .environment(\.quizMode, quizOn)
        .environment(\.quizSeed, quizSeed)
        .environment(\.quizCategory, quizCat)
        .environment(\.quizAnswersVisible, answersVisible)
        .onChange(of: quizOn) { _ in answersVisible = false; quizSeed += 1 }
        .onChange(of: quizCat) { _ in answersVisible = false; quizSeed += 1 }
    }

    // 暗記クイズの操作バー
    private var quizBar: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 11) {
                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.system(size: 15, weight: .bold)).foregroundColor(Theme.accent)
                    .frame(width: 34, height: 34)
                    .background(Theme.accent.opacity(0.14)).clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 1) {
                    Text("暗記クイズ").font(.system(size: 14.5, weight: .heavy)).foregroundColor(Theme.fg)
                    Text("重要語句をかくして思い出す").font(.system(size: 11)).foregroundColor(Theme.faint)
                }
                Spacer()
                Toggle("暗記クイズ", isOn: $quizOn).labelsHidden().tint(Theme.accent)
            }
            if quizOn {
                Picker("", selection: $quizCat) {
                    Text("すべて").tag("all")
                    Text("用語").tag("key")
                    Text("数値").tag("num")
                }
                .pickerStyle(.segmented)

                HStack(spacing: 10) {
                    Button { answersVisible.toggle() } label: {
                        HStack(spacing: 7) {
                            Image(systemName: answersVisible ? "eye.slash.fill" : "eye.fill").font(.system(size: 13, weight: .bold))
                            Text(answersVisible ? "答えを隠す" : "答えを表示").font(.system(size: 14.5, weight: .heavy))
                        }
                        .foregroundColor(Color(hex: 0x241703))
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(Theme.gold).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    Button { answersVisible = false; quizSeed += 1 } label: {
                        Image(systemName: "arrow.counterclockwise").font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.accent2)
                            .frame(width: 46, height: 46)
                            .background(Theme.raise).clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                Text("かくれた部分をタップで1つずつ、または「答えを表示」でまとめて確認できます。")
                    .font(.system(size: 11.5)).foregroundColor(Theme.faint).lineSpacing(3)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card2).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 1))
    }
}

/// 1ブロックを描画
struct BlockView: View {
    let block: TBBlock

    var body: some View {
        switch block.type {
        case "sub":
            MaskableText(raw: block.text ?? "", size: 16, weight: .bold, color: Theme.accent2, lineSpacingV: 5)
                .padding(.top, 12).padding(.bottom, 2)

        case "p":
            MaskableText(raw: block.text ?? "", terms: block.quizTerms ?? [], size: 15, color: Theme.fg, lineSpacingV: 9)
                .padding(.vertical, 2)

        case "ul":
            VStack(alignment: .leading, spacing: 13) {
                ForEach(Array((block.items ?? []).enumerated()), id: \.offset) { _, s in
                    HStack(alignment: .top, spacing: 12) {
                        Circle().fill(Theme.accent).frame(width: 5, height: 5).padding(.top, 9)
                        MaskableText(raw: s, terms: block.quizTerms ?? [], size: 15, color: Theme.fg, lineSpacingV: 7)
                    }
                }
            }
            .padding(.vertical, 2)

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
            VStack(alignment: .leading, spacing: 10) {
                if let name = block.asset {
                    FigureImageView(assetName: name,
                                    labels: block.labels ?? [],
                                    legend: block.legend ?? [],
                                    caption: block.caption,
                                    thumbMaxHeight: 300,
                                    showLegend: false)
                }
                if let cap = block.caption, !cap.isEmpty {
                    Text("図：" + cap).font(.system(size: 12)).foregroundColor(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let leg = block.legend, !leg.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(Array(leg.enumerated()), id: \.offset) { _, s in
                            Text("・" + s).font(.system(size: 12)).foregroundColor(Theme.muted)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.top, 3)
                }
            }
            .padding(.vertical, 4)

        case "svg":
            VStack(alignment: .leading, spacing: 10) {
                if let f = block.file {
                    SVGFigureView(file: f, caption: block.caption, thumbMaxHeight: 320)
                }
                if let cap = block.caption, !cap.isEmpty {
                    Text("図：" + cap).font(.system(size: 12)).foregroundColor(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let leg = block.legend, !leg.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(Array(leg.enumerated()), id: \.offset) { _, s in
                            Text("・" + s).font(.system(size: 12)).foregroundColor(Theme.muted)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.top, 3)
                }
            }
            .padding(.vertical, 4)

        case "table":
            TableBlock(headers: block.headers ?? [], rows: block.rows ?? [])

        case "point":
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 7) {
                    Image(systemName: "lightbulb.fill").font(.system(size: 13)).foregroundColor(Theme.accent)
                    Text("ここが出る").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.accent)
                }
                ForEach(Array((block.items ?? []).enumerated()), id: \.offset) { _, s in
                    HStack(alignment: .top, spacing: 11) {
                        Text("▶").font(.system(size: 9)).foregroundColor(Theme.accent).padding(.top, 6)
                        MaskableText(raw: s, terms: block.quizTerms ?? [], size: 14.5, weight: .medium, color: Theme.fg, lineSpacingV: 7)
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.accent.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.accent.opacity(0.35), lineWidth: 1))

        default:
            EmptyView()
        }
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
                    .padding(.horizontal, 15).padding(.vertical, 11)
                    .background(Theme.raise)
                }
                ForEach(Array(rows.enumerated()), id: \.offset) { i, r in
                    HStack(alignment: .top, spacing: 12) {
                        Text(attr(r.first ?? "")).font(.system(size: 13.5, weight: .semibold)).foregroundColor(Theme.fg)
                            .frame(width: 110, alignment: .leading)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                        if r.count > 1 {
                            Text(attr(r[1])).font(.system(size: 13.5)).foregroundColor(Theme.muted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 15).padding(.vertical, 13)
                    .background(i % 2 == 0 ? Theme.card : Theme.card2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
        } else {
            // 3列以上: 1行=1カード
            VStack(spacing: 12) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, r in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(attr(r.first ?? "")).font(.system(size: 14, weight: .bold)).foregroundColor(Theme.fg)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                        ForEach(1..<max(1, r.count), id: \.self) { j in
                            if j < headers.count {
                                HStack(alignment: .top, spacing: 8) {
                                    Text(headers[j]).font(.system(size: 11.5, weight: .semibold)).foregroundColor(Theme.accent2)
                                        .frame(width: 62, alignment: .leading)
                                    Text(attr(r[j])).font(.system(size: 13.5)).foregroundColor(Theme.muted)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineSpacing(5)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
                }
            }
        }
    }

    private func attr(_ s: String) -> AttributedString {
        if let a = try? AttributedString(markdown: s) { return a }
        return AttributedString(s)
    }
}
