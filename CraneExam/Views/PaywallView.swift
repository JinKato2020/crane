import SwiftUI

/// Pro(買い切り)購入画面。模試タブ・設定から .sheet で提示する。
struct PaywallView: View {
    @EnvironmentObject var purchases: PurchaseStore
    @Environment(\.dismiss) private var dismiss

    private let benefits = [
        "模擬試験 全8回(320問)がすべて解放",
        "本番形式・全問オリジナルの作り込み問題",
        "何度でも挑戦でき、成績・弱点も記録",
        "一度の購入でずっと使える(買い切り・定期課金なし)"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26)).foregroundColor(Theme.faint)
                    }
                }

                Image(systemName: "crown.fill")
                    .font(.system(size: 46)).foregroundColor(Theme.accent2)
                Text("クレーン Pro")
                    .font(.system(size: 26, weight: .heavy)).foregroundColor(Theme.fg)
                Text("すべての模擬試験を解放して、本番に備えましょう。")
                    .font(.system(size: 14)).foregroundColor(Theme.muted)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(benefits, id: \.self) { b in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.good).font(.system(size: 16))
                            Text(b).font(.system(size: 14)).foregroundColor(Theme.fg)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))

                Button {
                    Task { await purchases.buyPro() }
                } label: {
                    HStack(spacing: 8) {
                        if purchases.isWorking { ProgressView().tint(.white) }
                        Text(buttonTitle).font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(Theme.accent).foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(purchases.isWorking || purchases.isPro)

                Button {
                    Task { await purchases.restore() }
                } label: {
                    Text("購入を復元")
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.accent2)
                }

                Text("お支払いは Apple ID に請求されます。買い切りのため定期課金はありません。")
                    .font(.system(size: 11)).foregroundColor(Theme.faint)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onChange(of: purchases.isPro) { pro in
            if pro { dismiss() }
        }
        .alert("お知らせ", isPresented: Binding(
            get: { purchases.message != nil },
            set: { if !$0 { purchases.message = nil } }
        )) {
            Button("OK") { purchases.message = nil }
        } message: {
            Text(purchases.message ?? "")
        }
    }

    private var buttonTitle: String {
        if purchases.isPro { return "購入済み" }
        if let p = purchases.priceText { return "\(p) で解放(買い切り)" }
        return "Pro を購入"
    }
}
