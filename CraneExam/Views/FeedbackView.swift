import SwiftUI
import MessageUI

/// 読んだ画面を離れた時を、評価依頼の候補にする。バックグラウンド時間は数えない。
private struct StudyCompletionModifier: ViewModifier {
    let kind: StudyKind
    @EnvironmentObject private var store: ExamStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var exposure = StudyExposure()
    @State private var isVisible = false
    @State private var screenID = UUID()

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !isVisible else { return }
                isVisible = true
                store.beginStudyScreen(screenID)
                if scenePhase == .active { exposure.resume(at: Date()) }
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active && isVisible {
                    exposure.resume(at: Date())
                } else {
                    exposure.pause(at: Date())
                }
            }
            .onDisappear {
                guard isVisible else { return }
                let now = Date()
                store.endStudyScreen(screenID)
                if exposure.finish(at: now) {
                    store.recordStudyCompletion(kind: kind, at: now)
                }
                isVisible = false
            }
    }
}

extension View {
    func trackStudyCompletion(kind: StudyKind) -> some View { modifier(StudyCompletionModifier(kind: kind)) }
}

/// メールはユーザーが内容を確認し、送信を押したときにだけ送る。
struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showComposer = false
    @State private var mailFailed = false

    private var subject: String { "クレーン試験対策 ご意見・リクエスト" }
    private var draft: String {
        "ご意見・リクエストをご記入ください。\n\n\n\nアプリ：クレーン試験対策 \(SettingsView.appVersionText)"
    }
    private var mailURL: URL? {
        guard let email = SupportConfig.email else { return nil }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [URLQueryItem(name: "subject", value: subject), URLQueryItem(name: "body", value: draft)]
        return components.url
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("もっと学びやすいアプリに")
                        .font(.title2.bold()).foregroundColor(Theme.fg)
                    Text("分かりにくかった説明、欲しい機能、図や問題の気になる点などをお聞かせください。")
                        .foregroundColor(Theme.muted)
                    if let email = SupportConfig.email {
                        Text(email).textSelection(.enabled).foregroundColor(Theme.fg)
                        Button {
                            if MFMailComposeViewController.canSendMail() {
                                showComposer = true
                            } else if let url = mailURL {
                                openURL(url) { accepted in mailFailed = !accepted }
                            }
                        } label: {
                            Label("メールを作成", systemImage: "envelope")
                                .font(.headline).frame(maxWidth: .infinity).padding()
                                .background(Theme.accent).foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        if mailFailed {
                            Text("メールアプリを開けませんでした。上の宛先をコピーして、普段お使いのメールからお送りください。")
                                .foregroundColor(Theme.muted)
                        }
                    } else {
                        Text("メールの送信先は準備中です。")
                            .foregroundColor(Theme.muted)
                    }
                    Text("送信は任意です。メール作成画面で内容を確認・変更できます。")
                        .font(.footnote).foregroundColor(Theme.faint)
                }.padding(24)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("ご意見・リクエスト")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("閉じる") { dismiss() } } }
            .sheet(isPresented: $showComposer) {
                FeedbackMailComposer(subject: subject, bodyText: draft) { failed in
                    showComposer = false
                    mailFailed = failed
                }
            }
        }
    }
}

private struct FeedbackMailComposer: UIViewControllerRepresentable {
    let subject: String
    let bodyText: String
    let onFinish: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients(SupportConfig.email.map { [$0] } ?? [])
        controller.setSubject(subject)
        controller.setMessageBody(bodyText, isHTML: false)
        return controller
    }
    func updateUIViewController(_ controller: MFMailComposeViewController, context: Context) { }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onFinish: (Bool) -> Void
        init(onFinish: @escaping (Bool) -> Void) { self.onFinish = onFinish }
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult, error: Error?) {
            onFinish(error != nil || result == .failed)
        }
    }
}
