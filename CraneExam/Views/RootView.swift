import SwiftUI
import StoreKit
import UIKit

struct RootView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject private var store: ExamStore
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("cr_feedback_first_use") private var feedbackFirstUse: Double = 0
    @AppStorage("cr_feedback_last_request") private var feedbackLastRequest: Double = 0
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
        .onAppear {
            if feedbackFirstUse == 0 { feedbackFirstUse = Date().timeIntervalSince1970 }
        }
        .simultaneousGesture(TapGesture().onEnded { store.cancelPendingReview() })
        .simultaneousGesture(DragGesture(minimumDistance: 8).onChanged { _ in store.cancelPendingReview() })
        .task(id: store.feedbackOpportunityAt) {
            guard store.feedbackOpportunityAt != nil else { return }
            // 戻る遷移やシートの終了を待ってから、読書・解答を遮らず依頼する。
            do { try await Task.sleep(nanoseconds: 650_000_000) } catch { return }
            let interaction = store.studyInteractionRevision
            let tab = router.tab
            do { try await Task.sleep(nanoseconds: 1_350_000_000) } catch { return }
            guard !Task.isCancelled, scenePhase == .active,
                  store.activeStudyScreens.isEmpty,
                  store.studyInteractionRevision == interaction, router.tab == tab,
                  !hasPresentedSheet else { return }
            let now = Date()
            guard FeedbackSchedule.isDue(
                firstUse: Date(timeIntervalSince1970: feedbackFirstUse),
                lastRequest: feedbackLastRequest > 0 ? Date(timeIntervalSince1970: feedbackLastRequest) : nil,
                hasStudied: true, now: now) else { return }
            feedbackLastRequest = now.timeIntervalSince1970
            requestReview()
        }
    }

    private var hasPresentedSheet: Bool {
        func isPresenting(_ controller: UIViewController) -> Bool {
            controller.presentedViewController != nil || controller.children.contains(where: isPresenting)
        }
        return UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows).filter(\.isKeyWindow)
            .contains { window in
                guard let root = window.rootViewController else { return false }
                return isPresenting(root)
            }
    }
}
