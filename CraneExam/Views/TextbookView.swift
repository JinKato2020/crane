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
        .onAppear { rememberSection() }
        .onChange(of: index) { _ in rememberSection() }
        .trackStudyCompletion(kind: .textbook)
    }

    private func rememberSection() {
        guard secs.indices.contains(index) else { return }
        let section = secs[index]
        store.rememberStudy(StudyPlace(kind: .textbook, title: section.title,
                                       chapterID: chapter.id, sectionID: section.id))
    }
}

/// 1節ぶんの本文(スクロール)
struct SectionContentView: View {
    let section: TBSection
    let position: Int
    let total: Int

    @StateObject private var quiz: StudyQuizSession
    @State private var contentsExpanded = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(section: TBSection, position: Int, total: Int) {
        self.section = section
        self.position = position
        self.total = total
        _quiz = StateObject(wrappedValue: StudyQuizSession(section: section))
    }

    private var sectionHeadings: [(index: Int, title: String)] {
        section.blocks.enumerated().compactMap { index, block in
            guard block.type == "sub", let title = block.text else { return nil }
            return (index, title)
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(section.title)
                    .font(.system(size: 21, weight: .heavy)).foregroundColor(Theme.fg)
                    .lineSpacing(5)
                    .padding(.leading, 14)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(Theme.gold).frame(width: 4, height: 26)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10).padding(.bottom, 2)

                if !quiz.candidates.isEmpty { quizBar }

                if (section.id.hasPrefix("1-") || section.id.hasPrefix("2-") || section.id.hasPrefix("3-") || section.id.hasPrefix("4-")), sectionHeadings.count > 4 {
                    DisclosureGroup(isExpanded: $contentsExpanded) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(sectionHeadings, id: \.index) { heading in
                                Button {
                                    withAnimation { proxy.scrollTo(heading.index, anchor: .top) }
                                } label: {
                                    HStack(alignment: .top, spacing: 10) {
                                        Text(heading.title)
                                            .font(.system(size: 15, weight: .medium))
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer(minLength: 4)
                                        Image(systemName: "arrow.down").font(.system(size: 12))
                                    }
                                    .foregroundColor(Theme.accent2)
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                    .padding(.vertical, 5)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        Label("この節の目次", systemImage: "list.bullet")
                            .font(.system(size: 15, weight: .bold)).foregroundColor(Theme.fg)
                            .frame(minHeight: 32)
                    }
                    .tint(Theme.accent2)
                    .padding(16)
                    .background(Theme.card2)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                ForEach(Array(section.blocks.enumerated()), id: \.offset) { i, b in
                    BlockView(block: b, quizBlockID: StudyQuiz.blockID(section: section.id, index: i))
                        .id(i)
                }

                HStack(spacing: 6) {
                    Image(systemName: "hand.draw").font(.system(size: 11)).foregroundColor(Theme.faint)
                    Text(position < total ? "スワイプで次の節へ" : "この章の最後の節です")
                        .font(.system(size: 11)).foregroundColor(Theme.faint)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 20)
            }
            .padding(.horizontal, 20).padding(.vertical, 22)
        }
        .background(Theme.bg.ignoresSafeArea())
        .environment(\.quizMode, quiz.isOn)
        .environment(\.studyQuizSession, quiz)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if quiz.isOn && !quiz.selected.isEmpty { quizToolbar }
        }
        }
    }

    private func categoryTitle(_ category: String) -> String {
        switch category {
        case "key": return "用語・式"
        case "num": return "数値"
        default: return "すべて"
        }
    }

    private var quizBar: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $quiz.isOn) {
                VStack(alignment: .leading, spacing: 5) {
                    Label("暗記クイズ", systemImage: "brain.head.profile")
                        .font(.headline).foregroundColor(Theme.fg)
                    Text("本文の空欄を、頭の中で答える")
                        .font(.subheadline).foregroundColor(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(Theme.studyKey)
            .frame(minHeight: 44)
            .accessibilityHint("この節の重要な語句や数値を空欄にします")
            if quiz.isOn {
                if quiz.categories.count > 2 {
                    HStack {
                        Text("出題する内容").font(.subheadline).foregroundColor(Theme.muted)
                        Spacer(minLength: 4)
                        Picker("出題する内容", selection: $quiz.category) {
                            ForEach(quiz.categories, id: \.self) { category in
                                Text(categoryTitle(category)).tag(category)
                            }
                        }
                        .pickerStyle(.menu).tint(Theme.studyKey)
                        .frame(minHeight: 44)
                    }
                }
                Text("空欄をタップすると答えを確認できます。もう一度タップで隠せます。")
                    .font(.subheadline).foregroundColor(Theme.fg).lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                Text("1回に最大10か所。見出しや図はヒントに使えます。")
                    .font(.footnote).foregroundColor(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.studyKey.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.studyKey.opacity(0.22), lineWidth: 1))
    }

    private var quizToolbar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                Label("答えを確認 \(quiz.revealed.count) / \(quiz.selected.count)",
                      systemImage: quiz.allRevealed ? "checkmark.circle.fill" : "square.dashed")
                    .font(.subheadline.weight(.semibold)).foregroundColor(Theme.studyKey)
                    .monospacedDigit()
                    .accessibilityLabel("\(quiz.selected.count)か所のうち\(quiz.revealed.count)か所の答えを表示中")
                Spacer(minLength: 8)
                Button("終了") { quiz.isOn = false }
                    .font(.subheadline).foregroundColor(Theme.muted)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("暗記クイズを終了して本文を読む")
            }
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 8) { answerButton; if quiz.canChange { nextQuizButton } }
            } else {
                HStack(spacing: 10) { answerButton; if quiz.canChange { nextQuizButton } }
            }
        }
        .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 10)
        .background(Theme.card)
        .overlay(alignment: .top) { Rectangle().fill(Theme.line).frame(height: 1) }
    }

    private var answerButton: some View {
        Button { quiz.toggleAll() } label: {
            Label(quiz.answerLabel, systemImage: quiz.allRevealed ? "eye.slash" : "eye")
                .font(.body.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 48)
                .padding(.horizontal, 10)
                .foregroundColor(Theme.bg)
                .background(Theme.studyKey)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var nextQuizButton: some View {
        Button { quiz.nextRound() } label: {
            Text("別の出題").font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 48).padding(.horizontal, 12)
                .foregroundColor(Theme.studyKey)
                .background(Theme.studyKey.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityHint("この節の別の重要語句に切り替えて、答えを隠します")
    }
}

/// 1ブロックを描画
struct BlockView: View {
    let block: TBBlock
    var quizBlockID: String? = nil
    @State private var answerExpanded = false
    @State private var textbookReference: TextRef?

    var body: some View {
        switch block.type {
        case "sub":
            MaskableText(raw: block.text ?? "", size: 19, weight: .bold, color: Theme.fg, lineSpacingV: 6)
                .padding(.leading, 12)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Theme.studyKey).frame(width: 4)
                }
                .padding(.top, 20).padding(.bottom, 6)

        case "p":
            paragraph

        case "ul":
            VStack(alignment: .leading, spacing: 13) {
                ForEach(Array((block.items ?? []).enumerated()), id: \.offset) { i, s in
                    HStack(alignment: .top, spacing: 12) {
                        Circle().fill(Theme.accent).frame(width: 5, height: 5).padding(.top, 9)
                        MaskableText(raw: s, terms: block.quizTerms ?? [], quizField: StudyQuiz.fieldID(quizBlockID, "items:\(i)"), size: 15, color: Theme.fg, lineSpacingV: 7)
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
                                    thumbMaxHeight: block.style == "figure" ? 620 : 300,
                                    showLegend: false)
                }
                if let cap = block.caption, !cap.isEmpty {
                    Text("図：" + cap).font(.system(size: 13)).foregroundColor(Theme.muted)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let leg = block.legend, !leg.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(Array(leg.enumerated()), id: \.offset) { i, s in
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
                    SVGFigureView(file: f, caption: block.caption, thumbMaxHeight: block.style == "figure" ? 620 : 320)
                }
                if let cap = block.caption, !cap.isEmpty {
                    Text("図：" + cap).font(.system(size: 13)).foregroundColor(Theme.muted)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let leg = block.legend, !leg.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(Array(leg.enumerated()), id: \.offset) { i, s in
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
            TableBlock(headers: block.headers ?? [], rows: block.rows ?? [],
                       terms: block.quizTerms ?? [], numberStyle: block.style == "numbers",
                       matrixStyle: block.style == "matrix", quizBlockID: quizBlockID)

        case "point":
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 7) {
                    Image(systemName: "lightbulb.fill").font(.system(size: 13)).foregroundColor(Theme.accent)
                    Text("ここを覚える").font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.accent2)
                }
                ForEach(Array((block.items ?? []).enumerated()), id: \.offset) { i, s in
                    HStack(alignment: .top, spacing: 11) {
                        Text("▶").font(.system(size: 9)).foregroundColor(Theme.accent).padding(.top, 6)
                        MaskableText(raw: s, terms: block.quizTerms ?? [], quizField: StudyQuiz.fieldID(quizBlockID, "items:\(i)"), size: 16, weight: .medium, color: Theme.fg, lineSpacingV: 7)
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

    private var studyColor: Color {
        block.style == "caution" ? Theme.warn : Theme.studyKey
    }

    @ViewBuilder private var paragraph: some View {
        if block.style == "reference", let sectionID = block.file {
            Button {
                textbookReference = TextRef(section: sectionID, blockID: nil, anchor: nil, label: block.text)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "book")
                    Text(block.text ?? "関連する教材")
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.forward").font(.system(size: 12))
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.accent2)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(12)
                .background(Theme.card2)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .sheet(item: $textbookReference) { ref in
                TextbookRefSheet(ref: ref, closeLabel: "教材に戻る")
            }
        } else if block.style == "answer" {
            DisclosureGroup(isExpanded: $answerExpanded) {
                MaskableText(raw: block.text ?? "", size: 16, color: Theme.fg, lineSpacingV: 7)
                    .environment(\.quizMode, false)
                    .padding(.top, 12)
            } label: {
                Label(answerExpanded ? "答えと理由を閉じる" : "答えと理由を見る", systemImage: "checkmark.circle")
                    .font(.body.weight(.semibold))
                    .foregroundColor(Theme.studyKey)
                    .frame(minHeight: 44)
            }
            .tint(Theme.studyKey)
            .padding(16)
            .background(Theme.studyKey.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else if block.style == "question" {
            MaskableText(raw: block.text ?? "", size: 17, weight: .medium, color: Theme.fg, lineSpacingV: 8)
                .environment(\.quizMode, false)
                .padding(.vertical, 6)
        } else if let style = block.style, ["lead", "tip", "caution"].contains(style) {
            VStack(alignment: .leading, spacing: 10) {
                Label(style == "lead" ? "まず、これだけ" : (style == "tip" ? "なるほど" : "取り違え注意"),
                      systemImage: style == "lead" ? "bookmark.fill" : (style == "tip" ? "lightbulb" : "exclamationmark.circle"))
                    .font(.system(size: 13, weight: .bold)).foregroundColor(studyColor)
                MaskableText(raw: block.text ?? "", terms: block.quizTerms ?? [],
                             quizField: block.style == "lead" ? nil : StudyQuiz.fieldID(quizBlockID, "text"),
                             size: style == "lead" ? 18 : 16,
                             weight: style == "lead" ? .semibold : .regular,
                             color: Theme.fg, lineSpacingV: 7)
            }
            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(studyColor.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            MaskableText(raw: block.text ?? "", terms: block.quizTerms ?? [], quizField: StudyQuiz.fieldID(quizBlockID, "text"), size: 16, color: Theme.fg, lineSpacingV: 8)
                .padding(.vertical, 2)
        }
    }
}

/// 通常は2列の表／行カード。係数の比較表はmatrixで列をそろえる。
struct TableBlock: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let headers: [String]
    let rows: [[String]]
    var terms: [String] = []
    var numberStyle = false
    var matrixStyle = false
    var quizBlockID: String? = nil

    var body: some View {
        if numberStyle {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                    let value = row.dropFirst().joined(separator: " ／ ")
                    VStack(alignment: .leading, spacing: 9) {
                        MaskableText(raw: row.first ?? "", size: 14, weight: .semibold, color: Theme.muted, lineSpacingV: 5)
                        MaskableText(raw: value, terms: terms, quizField: StudyQuiz.fieldID(quizBlockID, "rows:\(i):value"),
                                     size: value.count > 36 ? 16 : 22, weight: .bold, color: Theme.fg, lineSpacingV: 7)
                    }
                    .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.studyKey.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        } else if dynamicTypeSize.isAccessibilitySize {
            accessibleRows
        } else if matrixStyle && headers.count == 4 {
            VStack(spacing: 0) {
                matrixRow(headers, isHeader: true, rowIndex: nil)
                    .background(Theme.raise)
                ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                    matrixRow(row, isHeader: false, rowIndex: i)
                        .background(i % 2 == 0 ? Theme.card : Theme.card2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
        } else if headers.count <= 2 {
            VStack(spacing: 0) {
                if !headers.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        Text(headers[0]).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if headers.count > 1 {
                            Text(headers[1]).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.muted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 15).padding(.vertical, 11)
                    .background(Theme.raise)
                }
                ForEach(Array(rows.enumerated()), id: \.offset) { i, r in
                    HStack(alignment: .top, spacing: 12) {
                        MaskableText(raw: r.first ?? "", terms: terms, quizField: StudyQuiz.fieldID(quizBlockID, "rows:\(i):0"), size: 15, weight: .semibold, color: Theme.fg, lineSpacingV: 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if r.count > 1 {
                            MaskableText(raw: r[1], terms: terms, quizField: StudyQuiz.fieldID(quizBlockID, "rows:\(i):1"), size: 15, color: Theme.fg, lineSpacingV: 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
                ForEach(Array(rows.enumerated()), id: \.offset) { i, r in
                    VStack(alignment: .leading, spacing: 8) {
                        MaskableText(raw: r.first ?? "", terms: terms, quizField: StudyQuiz.fieldID(quizBlockID, "rows:\(i):0"), size: 16, weight: .bold, color: Theme.fg, lineSpacingV: 5)
                        ForEach(1..<max(1, r.count), id: \.self) { j in
                            if j < headers.count {
                                HStack(alignment: .top, spacing: 8) {
                                    Text(headers[j]).font(.system(size: 11.5, weight: .semibold)).foregroundColor(Theme.accent2)
                                        .frame(width: 62, alignment: .leading)
                                    MaskableText(raw: r[j], terms: terms, quizField: StudyQuiz.fieldID(quizBlockID, "rows:\(i):\(j)"), size: 15, color: Theme.fg, lineSpacingV: 6)
                                        .frame(maxWidth: .infinity, alignment: .leading)
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

    /// At accessibility sizes, preserve row relationships without squeezing two or four columns.
    private var accessibleRows: some View {
        VStack(spacing: 14) {
            ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                let count = min(row.count, headers.count <= 2 ? 2 : headers.count)
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(0..<count, id: \.self) { column in
                        if column > 0 { Divider().overlay(Theme.line) }
                        VStack(alignment: .leading, spacing: 6) {
                            if column < headers.count {
                                Text(headers[column])
                                    .font(.caption.weight(.semibold)).foregroundColor(Theme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            MaskableText(raw: row[column], terms: terms,
                                         quizField: StudyQuiz.fieldID(quizBlockID, "rows:\(i):\(column)"),
                                         size: 16, weight: column == 0 ? .semibold : .regular,
                                         color: Theme.fg, lineSpacingV: 7)
                        }
                    }
                }
                .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
            }
        }
    }

    private func matrixRow(_ values: [String], isHeader: Bool, rowIndex: Int?) -> some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(0..<headers.count, id: \.self) { column in
                MaskableText(raw: column < values.count ? values[column] : "",
                             terms: terms,
                             quizField: !isHeader ? rowIndex.flatMap { StudyQuiz.fieldID(quizBlockID, "rows:\($0):\(column)") } : nil,
                             size: isHeader ? 13 : 15,
                             weight: isHeader || column == 0 ? .semibold : .regular,
                             color: isHeader ? Theme.muted : Theme.fg, lineSpacingV: 5)
                    .padding(.horizontal, 8)
                    .frame(width: column == 0 ? 120 : nil, alignment: .leading)
                    .frame(maxWidth: column == 0 ? nil : .infinity, alignment: .center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 12)
    }

    private func attr(_ s: String) -> AttributedString {
        if let a = try? AttributedString(markdown: s) { return a }
        return AttributedString(s)
    }
}
