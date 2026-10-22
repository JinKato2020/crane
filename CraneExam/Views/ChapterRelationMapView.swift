import SwiftUI

/// 部品の役割とつながりから教材の全体像を学ぶ。
struct ChapterRelationMapView: View {
    @EnvironmentObject var store: ExamStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("第1章 クレーンに関する知識")
                        .font(.system(size: 20, weight: .heavy)).foregroundColor(Theme.fg)
                    Text("荷が動くまでに、どの部品が何をするのか。つながりから全体像をつかみましょう。")
                        .font(.system(size: 14)).lineSpacing(5).foregroundColor(Theme.muted)
                    SVGFigureView(file: "chapter1_relation_map.svg", caption: "第1章の相関図", thumbMaxHeight: 440)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("相関図の読み方").font(.system(size: 16, weight: .bold))
                        Text("① 中央のクレーンから、枝の見出しを見ます。\n② 「動かす」「支える」「守る」の役割を結びつけます。\n③ 気になる枝を拡大し、教材で詳しく確認します。")
                            .font(.system(size: 14)).lineSpacing(7)
                    }
                    .foregroundColor(Theme.fg).padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 14))
                    if let chapter = store.textbook?.chapters.first(where: { $0.id == 1 }) {
                        NavigationLink {
                            ChapterSectionsView(chapter: chapter)
                        } label: {
                            Label("第1章の教材を読む", systemImage: "book")
                                .font(.system(size: 14, weight: .bold))
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered).tint(Theme.accent2)
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("相関図").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}
