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
                    Text("6つの役割から、部品の名前と働きを整理します。中心から外へ、太い枝から細い枝へたどってください。")
                        .font(.system(size: 14)).lineSpacing(5).foregroundColor(Theme.muted)
                    SVGFigureView(file: "chapter1_relation_map.svg", caption: "第1章の相関図", thumbMaxHeight: 440)
                    Label("図をタップして全画面へ。ピンチで枝の先まで拡大できます。", systemImage: "hand.draw")
                        .font(.system(size: 13)).lineSpacing(5)
                        .foregroundColor(Theme.muted)
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
