import SwiftUI

/// 間違えた問題・ブックマークのカードをタップで開く「問題の詳細」。
/// 問題文・条件図・選択肢（正解をハイライト）・解説・解説図をまとめて表示する。
struct QuestionDetailView: View {
    @EnvironmentObject var store: ExamStore
    @Environment(\.dismiss) private var dismiss
    let round: Int
    let q: Question

    private var bookmarkID: String { "\(round)-\(q.no)" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("第\(round)回 問\(q.no) · \(subjectShort(q.subject))")
                            .font(.system(size: 13, weight: .bold)).foregroundColor(Theme.muted)
                        Spacer()
                        Button { store.toggleBookmark(bookmarkID) } label: {
                            Image(systemName: store.isBookmarked(bookmarkID) ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(store.isBookmarked(bookmarkID) ? Theme.accent2 : Theme.muted)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(store.isBookmarked(bookmarkID) ? "ブックマーク解除" : "ブックマークに追加")
                    }

                    Text(q.text)
                        .font(.system(size: 16, weight: .bold)).foregroundColor(Theme.fg)
                        .fixedSize(horizontal: false, vertical: true).lineSpacing(5)

                    if let fig = q.figImg, !fig.isEmpty {
                        FigureImageView(assetName: fig, thumbMaxHeight: 230)
                    }

                    ForEach(Array(q.choices.enumerated()), id: \.offset) { i, c in
                        choiceRow(i, c)
                    }

                    explanationBox
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("問題の詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    // 復習表示：正解の肢を緑でハイライト
    private func choiceRow(_ i: Int, _ text: String) -> some View {
        let correct = (i == q.answer - 1)
        return HStack(alignment: .top, spacing: 12) {
            Text("\(i + 1)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .frame(width: 26, height: 26)
                .background(correct ? Theme.good : Theme.raise)
                .foregroundColor(correct ? Color(hex: 0x06230F) : Theme.muted)
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 13.5)).foregroundColor(Theme.fg)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading).lineSpacing(3)
        }
        .padding(13)
        .background(correct ? Theme.good.opacity(0.14) : Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(correct ? Theme.good : Theme.line, lineWidth: 1.5))
    }

    private var explanationBox: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("正解 (\(q.answer))")
                .font(.system(size: 13, weight: .heavy)).foregroundColor(Theme.good)
            Text("【解説】\(q.explanation)")
                .font(.system(size: 12.5)).foregroundColor(Theme.muted).lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            if let fe = q.figImgExp, !fe.isEmpty {
                FigureImageView(assetName: fe, thumbMaxHeight: 230)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card2)
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 11))
        .overlay(alignment: .leading) { Rectangle().fill(Theme.accent).frame(width: 3) }
    }
}
