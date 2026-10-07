import SwiftUI

/// 「学科」タブ：教材と用語集を収録。
struct StudyView: View {
    @EnvironmentObject var store: ExamStore
    @EnvironmentObject var router: Router

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    Picker("", selection: $router.studySeg) {
                        Text("教材").tag(0)
                        Text("用語").tag(1)
                    }
                    .pickerStyle(.segmented)

                    if router.studySeg == 1 {
                        GlossaryContent()
                    } else {
                        TextbookListView()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("学科")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STUDY")
                .font(.system(size: 11, weight: .semibold)).tracking(2)
                .foregroundColor(Theme.accent2)
            Text(router.studySeg == 1 ? "用語で確かめる" : "教材で理解する")
                .font(.system(size: 24, weight: .heavy)).foregroundColor(Theme.fg)
            Text(router.studySeg == 1
                 ? "全4章の重要用語を、図つきで検索できます。"
                 : "全4章を、図表とやさしい解説でひとつずつ。")
                .font(.system(size: 12.5)).foregroundColor(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }
}
