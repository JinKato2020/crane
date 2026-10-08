import SwiftUI
import RevenueCat

@main
struct CraneExamApp: App {
    @StateObject private var store = ExamStore()
    @StateObject private var router = Router()
    @StateObject private var purchases = PurchaseStore()
    // 0:システム 1:ライト 2:ダーク
    @AppStorage("cr_appearance") private var appearance: Int = 0

    init() {
        // 課金(RevenueCat)初期化 ― いちばん最初に行う
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: RCConfig.apiKey)

        // タブバー/ナビバー外観(明暗で自動追従する動的カラー)
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = Theme.uiDyn(0x14171E, 0xFFFFFF)
        tab.shadowColor = Theme.uiDyn(0x2A303C, 0xD6DBE3)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = Theme.uiDyn(0x0C0E12, 0xF4F6F9)
        let fg = Theme.uiDyn(0xEEF1F6, 0x1A1D22)
        nav.titleTextAttributes = [.foregroundColor: fg]
        nav.largeTitleTextAttributes = [.foregroundColor: fg]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
    }

    private var scheme: ColorScheme? {
        switch appearance {
        case 1: return .light
        case 2: return .dark
        default: return nil   // システム設定に従う
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(router)
                .environmentObject(purchases)
                .preferredColorScheme(scheme)
        }
    }
}
