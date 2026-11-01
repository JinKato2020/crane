import Foundation
import RevenueCat
import StoreKit

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
    @Published private(set) var hasPaidPro = false
    @Published private(set) var hasLifetimeFreeAccess: Bool
    var isPro: Bool { hasPaidPro || hasLifetimeFreeAccess }
    private let lifetimeKey = "cr_lifetime_free_access_v1"
    /// 販売中の Offering(RevenueCat の "current" offering)
    @Published var currentOffering: Offering?
    /// 購入/復元の処理中
    @Published var isWorking = false
    /// 画面に出すお知らせ(エラー・復元結果など)
    @Published var message: String?

    init() {
        hasLifetimeFreeAccess = PromotionPolicy.enrollmentOpen
            || UserDefaults.standard.bool(forKey: "cr_lifetime_free_access_v1")
        if PromotionPolicy.enrollmentOpen {
            UserDefaults.standard.set(true, forKey: lifetimeKey)
        }
        Task {
            await refresh()
            if !isPro { await loadOfferings() }
        }
    }

    /// 購入状態を最新化
    func refresh() async {
        await restoreFreeAccess()
        if let info = try? await Purchases.shared.customerInfo() {
            hasPaidPro = info.entitlements[RCConfig.entitlementID]?.isActive == true
        }
    }

    /// Apple署名を検証した初回取得日で、無料公開終了後の再取得も復元する。
    private func restoreFreeAccess() async {
        guard let result = try? await AppTransaction.shared,
              case .verified(let transaction) = result,
              PromotionPolicy.qualifies(originalPurchaseDate: transaction.originalPurchaseDate) else { return }
        hasLifetimeFreeAccess = true
        UserDefaults.standard.set(true, forKey: lifetimeKey)
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
        guard !isPro else { return }
        guard let pkg = proPackage else {
            message = "商品を読み込めませんでした。通信環境を確認し、少し待って再度お試しください。"
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            let result = try await Purchases.shared.purchase(package: pkg)
            if result.userCancelled { return }
            hasPaidPro = result.customerInfo.entitlements[RCConfig.entitlementID]?.isActive == true
        } catch {
            message = "購入に失敗しました：\(error.localizedDescription)"
        }
    }

    /// 購入を復元する(機種変更・再インストール時)
    func restore() async {
        isWorking = true
        defer { isWorking = false }
        await restoreFreeAccess()
        if hasLifetimeFreeAccess {
            message = "無期限の無料利用が有効です。教材・模試・用語・相関図をすべて使えます。"
            return
        }
        if let info = try? await Purchases.shared.restorePurchases() {
            hasPaidPro = info.entitlements[RCConfig.entitlementID]?.isActive == true
            message = isPro ? "Pro を復元しました。" : "復元できる購入が見つかりませんでした。"
        } else {
            message = "復元に失敗しました。通信環境をご確認ください。"
        }
    }
}
