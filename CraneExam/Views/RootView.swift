import SwiftUI

struct RootView: View {
    @EnvironmentObject var router: Router
    var body: some View {
        // 表示順＝ホーム/教材/用語/模試・成績/設定。
        // tag は router.tab の識別子（HomeView等が参照）なので値は固定し、並びだけ入れ替える。
        TabView(selection: $router.tab) {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house.fill") }.tag(0)
            StudyView()
                .tabItem { Label("教材", systemImage: "book.fill") }.tag(1)
            GlossaryView()
                .tabItem { Label("用語", systemImage: "character.book.closed.fill") }.tag(3)
            MockExamView()
                .tabItem { Label("模試・成績", systemImage: "doc.text.fill") }.tag(2)
            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape.fill") }.tag(4)
        }
        .tint(Theme.accent)
    }
}
