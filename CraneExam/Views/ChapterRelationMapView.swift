import SwiftUI

/// 各章のテーマとつながりから教材の全体像を学ぶ。
struct ChapterRelationMapView: View {
    @EnvironmentObject var store: ExamStore
    @EnvironmentObject var purchases: PurchaseStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedChapter = 1
    @State private var showPaywall = false

    private var chapterTitle: String {
        store.textbook?.chapters.first(where: { $0.id == selectedChapter })?.title
            ?? ["クレーンに関する知識", "関係法令", "原動機及び電気に関する知識", "クレーンの運転のために必要な力学に関する知識"][selectedChapter - 1]
    }

    // 無料プランで第2章以降を選んだときのロック表示。
    private var lockCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill").font(.system(size: 34)).foregroundColor(Theme.accent2)
            Text("第\(selectedChapter)章の相関図は Pro で解放")
                .font(.system(size: 15, weight: .bold)).foregroundColor(Theme.fg)
                .multilineTextAlignment(.center)
            Text("無料プランでは第1章の相関図をご覧いただけます。")
                .font(.system(size: 12.5)).foregroundColor(Theme.muted)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            Button { showPaywall = true } label: {
                Text("Proで全章を解放")
                    .font(.system(size: 14, weight: .heavy)).foregroundColor(Color(hex: 0x241703))
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Theme.gold).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity).padding(24)
        .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("章を選ぶ", selection: $selectedChapter) {
                        ForEach(1...4, id: \.self) { number in
                            Text("第\(number)章").tag(number)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("相関図の章を選ぶ")
                    Text("第\(selectedChapter)章 \(chapterTitle)")
                        .font(.system(size: 20, weight: .heavy)).foregroundColor(Theme.fg)
                    if selectedChapter != 1 && !purchases.isPro {
                        lockCard
                    } else {
                        Text("6つのテーマから、役割としくみを整理します。中心から外へ、太い枝から細い枝へたどってください。")
                            .font(.system(size: 14)).lineSpacing(5).foregroundColor(Theme.muted)
                        SVGFigureView(file: "chapter\(selectedChapter)_relation_map.svg", caption: "第\(selectedChapter)章の相関図", thumbMaxHeight: 440)
                            .id(selectedChapter)
                        Label("図をタップして全画面へ。ピンチで枝の先まで拡大できます。", systemImage: "hand.draw")
                            .font(.system(size: 13)).lineSpacing(5)
                            .foregroundColor(Theme.muted)
                        if let chapter = store.textbook?.chapters.first(where: { $0.id == selectedChapter }) {
                            NavigationLink {
                                ChapterSectionsView(chapter: chapter)
                            } label: {
                                Label("第\(selectedChapter)章の教材を読む", systemImage: "book")
                                    .font(.system(size: 14, weight: .bold))
                                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered).tint(Theme.accent2)
                        }
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .navigationTitle("相関図").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("相関図を閉じる")
                }
            }
        }
    }
}
