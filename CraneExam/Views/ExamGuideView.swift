import SwiftUI

/// クレーン試験の総合解説（ホームから開く）。時間・配点・合格基準・受験の流れ。
struct ExamGuideView: View {
    @Environment(\.dismiss) private var dismiss

    private let subjects: [(String, String, String)] = [
        ("クレーンに関する知識", "10問", "30点"),
        ("原動機及び電気に関する知識", "10問", "30点"),
        ("クレーンの運転に必要な力学", "10問", "20点"),
        ("関係法令", "10問", "20点"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    briefingImage
                    overviewCard
                    timeCard
                    scoringCard
                    passCard
                    examDayCard
                    practicalCard
                    flowCard
                    linksCard
                    Text("申込・試験日程・受験地・受験資格などの最新情報は、必ず公式サイトでご確認ください。")
                        .font(.system(size: 11.5)).foregroundColor(Theme.faint)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 28)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("総合解説")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }.foregroundColor(Theme.accent)
                }
            }
        }
    }

    // 総合解説の冒頭バナー（作業前ミーティングの様子）。学習の導入としてヘッダー直後に置く。
    private var briefingImage: some View {
        Image("WorkshopBriefing")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity)
            .frame(height: 172)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.line, lineWidth: 1))
            .accessibilityLabel("作業開始前のミーティングの様子")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EXAM GUIDE")
                .font(.system(size: 11, weight: .semibold)).tracking(2).foregroundColor(Theme.accent2)
            Text("クレーン・デリック運転士試験とは")
                .font(.system(size: 23, weight: .heavy)).foregroundColor(Theme.fg)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }

    private var overviewCard: some View {
        Card(padding: 18) {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("試験の概要", "info.circle.fill")
                body("クレーンを安全に運転するための国家試験です。科目免除がない場合、学科試験は **全4科目・合計40問**。5つの選択肢から、問題の指示に合う答えを1つ選ぶ **五肢択一式** です。")
                body("このアプリの「クレーン限定」では、デリックに関する問題は出題範囲から除かれます。")
            }
        }
    }

    private var timeCard: some View {
        Card(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("試験時間", "clock.fill")
                Text(CraneExamFormat.durationLabel)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.accent2)
                body("**\(CraneExamFormat.durationMinutes)分で40問**。通常は **13:30〜16:00** です。")
                bullet("**力学が免除の場合：2時間・30問**（通常13:30〜15:30）")
                body("出張試験は開始時刻が会場によって異なります。受験票の時刻を確認しましょう。")
                Divider().overlay(Theme.line)
                body("このアプリの模試は **科目免除なしの40問**。開始前に **時間制限あり（150分）／なし** を選べます。ありの場合は残り時間を表示し、150分で自動終了・採点。未回答は不正解になります。なしの場合は経過時間を表示します。")
            }
        }
    }

    private var scoringCard: some View {
        Card(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("科目と配点", "list.bullet.rectangle.fill")
                VStack(spacing: 8) {
                    ForEach(Array(subjects.enumerated()), id: \.offset) { _, s in
                        HStack(spacing: 10) {
                            Text(s.0).font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.fg)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Text(s.1).font(.system(size: 12)).foregroundColor(Theme.muted)
                            Text(s.2).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(Theme.accent2)
                                .frame(width: 42, alignment: .trailing)
                        }
                        .padding(.vertical, 3)
                        Divider().overlay(Theme.line)
                    }
                    HStack {
                        Text("合計").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.fg)
                        Spacer()
                        Text("40問").font(.system(size: 12)).foregroundColor(Theme.muted)
                        Text("100点").font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundColor(Theme.accent)
                            .frame(width: 42, alignment: .trailing)
                    }
                    .padding(.top, 2)
                }
            }
        }
    }

    private var passCard: some View {
        Card(padding: 18) {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("合格基準", "checkmark.seal.fill")
                body("次の **両方** を満たすと合格です。")
                bullet("**各科目で40%以上**：それぞれ10問中 **4問以上** 正解")
                bullet("**総合60点以上／100点**：4科目の得点を合計")
                Text("配点が科目で違うため、「40問中24問正解」で単純に判断できません。苦手科目を作らないことが大切です。")
                    .font(.system(size: 12)).foregroundColor(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true).padding(.top, 2)
            }
        }
    }

    private var examDayCard: some View {
        Card(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("本番で覚えておきたいこと", "checkmark.square.fill")
                bullet("解答は **マークシート**。1問につき **1つだけ** マークします。")
                bullet("筆記具は **HBまたはBの鉛筆・シャープペンシル** と消しゴムを用意。")
                bullet("試験開始から **1時間以内は退室できません**。退室後の再入室もできません。")
                body("計算・メモは試験問題の余白を使います。最後に、問題番号とマークする欄がずれていないか確認しましょう。")
            }
        }
    }

    private var practicalCard: some View {
        Card(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("学科と実技の関係", "figure.walk")
                body("実技が免除されない場合は、学科に加えて **「クレーンの運転」「運転のための合図」** の実技試験があります。実技の集合時刻は受験票で確認します。")
                body("所定の **クレーン運転実技教習** の修了などにより、実技試験が免除される場合があります。免除の条件と必要書類は公式案内で確認できます。")
            }
        }
    }

    private var flowCard: some View {
        Card(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("合格までの学び方", "figure.walk")
                step("1", "教材で理解する", "「学科」タブの教材で、全4章をやさしい解説と図で学ぶ。")
                step("2", "用語を確かめる", "「学科」タブの用語で、重要用語を図つきで確認。")
                step("3", "模試で力試し", "「模試」タブで40問に挑戦。本試験と同じ\(CraneExamFormat.durationLabel)を目安に練習。")
                step("4", "弱点を復習", "「模試」タブの「成績を確認する」から、間違えた問題と関連する教材を見直す。")
            }
        }
    }

    private var linksCard: some View {
        Card(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("公式リンク", "link")
                linkRow("公益財団法人 安全衛生技術試験協会（公式）", "https://www.exam.or.jp/")
                linkRow("クレーン限定：試験時間・配点・免除条件", "https://www.exam.or.jp/introduction/h_shokai206/")
                linkRow("クレーン限定：試験日程", "https://www.exam.or.jp/schedule/h_nittei206/")
                linkRow("公式公表問題：解答方法・当日の注意事項", "https://www.exam.or.jp/wp-content/uploads/2026/04/%E3%82%AF%E3%83%AC%E3%83%BC%E3%83%B3%E9%99%90%E5%AE%9A%E5%85%AC%E8%A1%A8%E8%A9%A6%E9%A8%93%E5%95%8F%E9%A1%8C-3.pdf")
                Text("試験情報の確認日：2026年11月1日")
                    .font(.system(size: 12)).foregroundColor(Theme.muted)
            }
        }
    }

    // MARK: パーツ
    private func sectionTitle(_ t: String, _ icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(Theme.accent)
            Text(t).font(.system(size: 15, weight: .heavy)).foregroundColor(Theme.fg)
        }
    }

    private func body(_ s: String) -> some View {
        Text(md(s)).font(.system(size: 13.5)).foregroundColor(Theme.fg).lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bullet(_ s: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(Theme.accent).frame(width: 5, height: 5).padding(.top, 7)
            Text(md(s)).font(.system(size: 13.5)).foregroundColor(Theme.fg).lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func step(_ n: String, _ title: String, _ sub: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(n).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(Color(hex: 0x241703))
                .frame(width: 26, height: 26).background(Theme.gold).clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13.5, weight: .bold)).foregroundColor(Theme.fg)
                Text(sub).font(.system(size: 12)).foregroundColor(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func linkRow(_ title: String, _ url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.up.right.square").font(.system(size: 14)).foregroundColor(Theme.accent2)
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.fg)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
            }
        }
    }

    private func md(_ s: String) -> AttributedString {
        (try? AttributedString(markdown: s)) ?? AttributedString(s)
    }
}
