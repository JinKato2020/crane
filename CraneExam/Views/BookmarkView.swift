import SwiftUI

/// ブックマーク一覧（ホームから独立した画面として開く）。
/// 問題画面のしおりで保存した問題をまとめて見返し、タップで問題の詳細を開く。
struct BookmarkView: View {
    @EnvironmentObject var store: ExamStore
    @Environment(\.dismiss) private var dismiss
    @State private var detail: QDetail?

    struct QDetail: Identifiable {
        let round: Int; let q: Question
        var id: String { "\(round)-\(q.no)" }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                let items = store.bookmarkedQuestions()
                VStack(alignment: .leading, spacing: 12) {
                    if items.isEmpty {
                        empty("bookmark", "ブックマークはありません",
                              "問題画面のしおりアイコンを押すと、ここに保存されます。")
                    } else {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, pair in
                            QCard(round: pair.0.round, q: pair.1,
                                  tagColor: Theme.accent2, tagText: "保存済",
                                  showBookmarkToggle: true) {
                                detail = QDetail(round: pair.0.round, q: pair.1)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("ブックマーク")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .sheet(item: $detail) { d in
                QuestionDetailView(round: d.round, q: d.q).environmentObject(store)
            }
        }
    }

    private func empty(_ icon: String, _ title: String, _ sub: String) -> some View {
        VStack(spacing: 11) {
            Image(systemName: icon).font(.system(size: 40)).foregroundColor(Theme.faint)
            Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(Theme.fg)
            Text(sub).font(.system(size: 12)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60)
    }
}
