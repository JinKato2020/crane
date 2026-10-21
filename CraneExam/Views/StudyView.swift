import SwiftUI

/// 「教材」タブ：全4章の教材（用語は独立した「用語」タブへ分離）。
struct StudyView: View {
    @EnvironmentObject var store: ExamStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    TextbookListView()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("教材")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STUDY")
                .font(.system(size: 11, weight: .semibold)).tracking(2)
                .foregroundColor(Theme.accent2)
            Text("教材で理解する")
                .font(.system(size: 24, weight: .heavy)).foregroundColor(Theme.fg)
            Text("全4章を、図表とやさしい解説でひとつずつ。")
                .font(.system(size: 12.5)).foregroundColor(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }
}
