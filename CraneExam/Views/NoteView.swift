import SwiftUI

struct NoteView: View {
    @EnvironmentObject var store: ExamStore
    @EnvironmentObject var router: Router

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("", selection: $router.noteSeg) {
                        Text("間違えた問題").tag(0)
                        Text("ブックマーク").tag(1)
                        Text("メモ").tag(2)
                    }.pickerStyle(.segmented)

                    switch router.noteSeg {
                    case 0: wrongList
                    case 1: bookmarkList
                    default: memoList
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("マイノート")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var wrongList: some View {
        Group {
            if store.wrongs.isEmpty {
                empty("checkmark.seal", "間違えた問題はありません", "模擬試験で間違えた問題がここに集まります。")
            } else {
                ForEach(store.wrongs) { w in
                    if let q = store.question(w) {
                        qCard(round: w.round, q: q, tagColor: Theme.warn, tagText: "要復習")
                    }
                }
            }
        }
    }

    private var bookmarkList: some View {
        let items = store.bookmarkedQuestions()
        return Group {
            if items.isEmpty {
                empty("bookmark", "ブックマークはありません", "問題画面のしおりアイコンで保存できます。")
            } else {
                ForEach(items, id: \.1.id) { pair in
                    qCard(round: pair.0.round, q: pair.1, tagColor: Theme.accent2, tagText: "保存済")
                }
            }
        }
    }

    private var memoList: some View {
        empty("square.and.pencil", "メモ機能は準備中です", "今後のアップデートで、自分用のメモを追加できるようになります。")
    }

    private func qCard(round: Int, q: Question, tagColor: Color, tagText: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("第\(round)回 問\(q.no) · \(subjectShort(q.subject))")
                    .font(.system(size: 12.5, weight: .bold)).foregroundColor(Theme.fg)
                Spacer()
                Pill(text: tagText, fg: tagColor, bg: tagColor.opacity(0.18))
            }
            Text(q.text).font(.system(size: 12.5)).foregroundColor(Theme.muted)
                .lineLimit(3).fixedSize(horizontal: false, vertical: true)
            if q.answer - 1 < q.choices.count {
                Text("正解 (\(q.answer)) \(q.choices[q.answer - 1])")
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.good)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
    }

    private func empty(_ icon: String, _ title: String, _ sub: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 38)).foregroundColor(Theme.faint)
            Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(Theme.fg)
            Text(sub).font(.system(size: 12)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 50)
    }
}
