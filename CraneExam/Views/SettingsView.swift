import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var purchases: PurchaseStore
    @AppStorage("cr_notify") private var notify: Bool = true
    @AppStorage("cr_appearance") private var appearance: Int = 0   // 0:システム 1:ライト 2:ダーク
    @State private var showPaywall = false

    // Info.plist(＝project.yml の MARKETING_VERSION / CURRENT_PROJECT_VERSION)から実行時に読む。
    // これでビルドのたびに手で書き換える必要がなく、実バージョンと必ず一致する。
    static var appVersionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 9) {
                    group("プラン")
                    planSection

                    group("学習")
                    toggleRow("bell.fill", "学習リマインダー通知", "毎日 20:00", $notify)

                    group("表示")
                    appearanceRow

                    group("データ")
                    infoRow("externaldrive.fill", "学習データ", "この端末に保存")

                    group("アプリについて")
                    infoRow("info.circle.fill", "バージョン", Self.appVersionText)

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
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("お知らせ", isPresented: Binding(
                get: { purchases.message != nil },
                set: { if !$0 { purchases.message = nil } }
            )) {
                Button("OK") { purchases.message = nil }
            } message: {
                Text(purchases.message ?? "")
            }
        }
    }

    // プラン(Pro購入/復元)セクション
    private var planSection: some View {
        VStack(spacing: 9) {
            if purchases.isPro {
                HStack(spacing: 12) {
                    iconBox("crown.fill")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("クレーン Pro 有効").font(.system(size: 13.5, weight: .bold)).foregroundColor(Theme.fg)
                        Text("すべての模擬試験が使えます").font(.system(size: 11)).foregroundColor(Theme.faint)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.good).font(.system(size: 16))
                }
                .rowStyle()
            } else {
                Button { showPaywall = true } label: {
                    HStack(spacing: 12) {
                        iconBox("crown.fill")
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Proにアップグレード").font(.system(size: 13.5, weight: .bold)).foregroundColor(Theme.fg)
                            Text("模擬試験 全8回を解放(買い切り)").font(.system(size: 11)).foregroundColor(Theme.faint)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.faint)
                    }
                    .rowStyle()
                }
                .buttonStyle(.plain)
            }

            Button {
                Task { await purchases.restore() }
            } label: {
                HStack(spacing: 12) {
                    iconBox("arrow.clockwise")
                    Text("購入を復元").font(.system(size: 13.5, weight: .bold)).foregroundColor(Theme.fg)
                    Spacer()
                    if purchases.isWorking { ProgressView() }
                }
                .rowStyle()
            }
            .buttonStyle(.plain)
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

    private var appearanceRow: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 12) {
                iconBox("circle.lefthalf.filled")
                VStack(alignment: .leading, spacing: 2) {
                    Text("外観").font(.system(size: 13.5, weight: .bold)).foregroundColor(Theme.fg)
                    Text("ライト／ダークを選べます").font(.system(size: 11)).foregroundColor(Theme.faint)
                }
                Spacer()
            }
            Picker("", selection: $appearance) {
                Text("システム").tag(0)
                Text("ライト").tag(1)
                Text("ダーク").tag(2)
            }.pickerStyle(.segmented)
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
