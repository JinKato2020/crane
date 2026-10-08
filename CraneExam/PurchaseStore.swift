import Foundation
import RevenueCat

/// RevenueCat の設定値。
/// apiKey は RevenueCat ダッシュボード → API keys → Apple 用の「公開(public)キー」(appl_ で始まる)に差し替える。
/// ※公開キーなのでアプリに埋め込んで問題ない。
enum RCConfig {
    static let apiKey = "appl_mmDJhppPKIjFmWNeIcQHhPNOWcK"
    /// RevenueCat の Entitlement 識別子(購入で解放する権利)。
    static let entitlementID = "pro"
}

/// 課金状態(Pro 解放)を管理する軽量ストア。EnvironmentObject で全画面に配る。
@MainActor
final class PurchaseStore: ObservableObject {
    /// Pro(買い切り)を所持しているか
    @Published var isPro = false
    /// 販売中の Offering(RevenueCat の "current" offering)
    @Published var currentOffering: Offering?
    /// 購入/復元の処理中
    @Published var isWorking = false
    /// 画面に出すお知らせ(エラー・復元結果など)
    @Published var message: String?

    init() {
        Task {
            await refresh()
            await loadOfferings()
        }
    }

    /// 購入状態を最新化
    func refresh() async {
        if let info = try? await Purchases.shared.customerInfo() {
            isPro = info.entitlements[RCConfig.entitlementID]?.isActive == true
        }
    }

    /// 販売商品(default offering)を読み込む
    func loadOfferings() async {
        currentOffering = try? await Purchases.shared.offerings().current
    }

    /// Pro の買い切りパッケージ(Lifetime)
    var proPackage: Package? {
        currentOffering?.lifetime ?? currentOffering?.availablePackages.first
    }

    /// 表示用の価格文字列(例: ¥480)
    var priceText: String? {
        proPackage?.storeProduct.localizedPriceString
    }

    /// 購入する
    func buyPro() async {
        guard let pkg = proPackage else {
            message = "商品を読み込めませんでした。通信環境を確認し、少し待って再度お試しください。"
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            let result = try await Purchases.shared.purchase(package: pkg)
            if result.userCancelled { return }
            isPro = result.customerInfo.entitlements[RCConfig.entitlementID]?.isActive == true
        } catch {
            message = "購入に失敗しました：\(error.localizedDescription)"
        }
    }

    /// 購入を復元する(機種変更・再インストール時)
    func restore() async {
        isWorking = true
        defer { isWorking = false }
        if let info = try? await Purchases.shared.restorePurchases() {
            isPro = info.entitlements[RCConfig.entitlementID]?.isActive == true
            message = isPro ? "Pro を復元しました。" : "復元できる購入が見つかりませんでした。"
        } else {
            message = "復元に失敗しました。通信環境をご確認ください。"
        }
    }
}
