import SwiftUI

// Keep the current review card's colors independent of the reverted home redesign.
private enum ReviewSupportStyle {
    static let teal = Color(Theme.uiDyn(0x95D5CA, 0x286D70))
    static let tealFill = Color(Theme.uiDyn(0x203D42, 0xE8F3F0))
}

/// A persistent, voluntary App Store link; automatic prompts use StoreKit only.
struct ReviewSupportCard: View {
    @State private var showFeedback = false
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                Text("App Storeで感想を共有").font(.subheadline.bold()).foregroundColor(ReviewSupportStyle.teal)
                Text("その感想が、次に学ぶ人の参考に。")
                    .font(.title3.bold()).foregroundColor(Theme.fg).fixedSize(horizontal: false, vertical: true)
                Text("教材の分かりやすさや使い心地など、使って感じたことをお聞かせください。")
                    .font(.subheadline).foregroundColor(Theme.muted).fixedSize(horizontal: false, vertical: true)
                Link(destination: URL(string: "https://apps.apple.com/app/id6818800945?action=write-review")!) {
                    Label("App Storeで評価する", systemImage: "star")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 48).padding(.vertical, 4)
                        .background(Color(hex: 0x285F71)).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Text("星だけの評価でも大丈夫です。")
                    .font(.footnote).foregroundColor(Theme.muted).frame(maxWidth: .infinity)
            }.padding(18).background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
            VStack(alignment: .leading, spacing: 10) {
                Text("もっと学びやすくするアイデアを").font(.headline).foregroundColor(Theme.fg)
                Text("分かりにくい説明や欲しい機能など、開発者へのご意見はこちらへ。")
                    .font(.subheadline).foregroundColor(Theme.muted).fixedSize(horizontal: false, vertical: true)
                Button { showFeedback = true } label: {
                    Label("ご意見・リクエストを送る", systemImage: "envelope")
                        .font(.subheadline.bold()).foregroundColor(ReviewSupportStyle.teal)
                        .frame(maxWidth: .infinity, minHeight: 48).padding(.vertical, 3)
                        .background(ReviewSupportStyle.tealFill).clipShape(RoundedRectangle(cornerRadius: 12))
                }.buttonStyle(.plain)
            }.padding(18).background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
        }.sheet(isPresented: $showFeedback) { FeedbackView() }
    }
}
