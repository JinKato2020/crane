import SwiftUI

struct SettingsView: View {
    @AppStorage("cr_goal") private var goal: Int = 20
    @AppStorage("cr_notify") private var notify: Bool = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 9) {
                    group("学習")
                    Stepperish(title: "1日の目標問題数", value: $goal, range: 5...100, step: 5, unit: "問")
                    toggleRow("bell.fill", "学習リマインダー通知", "毎日 20:00", $notify)

                    group("表示")
                    infoRow("moon.fill", "ダークモード", "常にオン")

                    group("データ")
                    infoRow("externaldrive.fill", "学習データ", "この端末に保存")

                    group("アプリについて")
                    infoRow("info.circle.fill", "バージョン", "1.0.0 (内部配信)")

                    Text("BUILD A SAFER TOMORROW")
                        .font(.system(size: 10, weight: .bold)).tracking(1)
                        .foregroundColor(Theme.faint)
                        .frame(maxWidth: .infinity).padding(.top, 18)
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func group(_ t: String) -> some View {
        Text(t).font(.system(size: 11, weight: .bold)).tracking(1)
            .foregroundColor(Theme.faint)
            .padding(.top, 10).padding(.leading, 2)
    }

    private func toggleRow(_ icon: String, _ title: String, _ sub: String, _ bind: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            iconBox(icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13.5, weight: .bold)).foregroundColor(Theme.fg)
                Text(sub).font(.system(size: 11)).foregroundColor(Theme.faint)
            }
            Spacer()
            Toggle("", isOn: bind).labelsHidden().tint(Theme.accent)
        }
        .rowStyle()
    }

    private func infoRow(_ icon: String, _ title: String, _ sub: String) -> some View {
        HStack(spacing: 12) {
            iconBox(icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13.5, weight: .bold)).foregroundColor(Theme.fg)
                Text(sub).font(.system(size: 11)).foregroundColor(Theme.faint)
            }
            Spacer()
        }
        .rowStyle()
    }

    private func iconBox(_ icon: String) -> some View {
        Image(systemName: icon).font(.system(size: 14))
            .foregroundColor(Theme.accent2)
            .frame(width: 34, height: 34)
            .background(Theme.raise).clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct Stepperish: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let unit: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "target").font(.system(size: 14)).foregroundColor(Theme.accent2)
                .frame(width: 34, height: 34).background(Theme.raise).clipShape(RoundedRectangle(cornerRadius: 10))
            Text(title).font(.system(size: 13.5, weight: .bold)).foregroundColor(Theme.fg)
            Spacer()
            Stepper("\(value)\(unit)", value: $value, in: range, step: step)
                .labelsHidden()
            Text("\(value)\(unit)").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(Theme.accent2)
                .frame(width: 48, alignment: .trailing)
        }
        .rowStyle()
    }
}

private extension View {
    func rowStyle() -> some View {
        self.padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
    }
}
