import SwiftUI

struct RootView: View {
    @EnvironmentObject var router: Router
    var body: some View {
        TabView(selection: $router.tab) {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house.fill") }.tag(0)
            StudyView()
                .tabItem { Label("学科", systemImage: "book.fill") }.tag(1)
            MockExamView()
                .tabItem { Label("模試", systemImage: "doc.text.fill") }.tag(2)
            ScoreView()
                .tabItem { Label("成績", systemImage: "chart.bar.fill") }.tag(3)
            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape.fill") }.tag(4)
        }
        .tint(Theme.accent)
    }
}
