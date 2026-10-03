import SwiftUI

@main
struct CraneExamApp: App {
    @StateObject private var store = ExamStore()
    @StateObject private var router = Router()

    init() {
        // ダークなタブバー/ナビバー外観
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(Theme.panel)
        tab.shadowColor = UIColor(Theme.line)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(Theme.bg)
        nav.titleTextAttributes = [.foregroundColor: UIColor(Theme.fg)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(Theme.fg)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(router)
                .preferredColorScheme(.dark)
        }
    }
}
