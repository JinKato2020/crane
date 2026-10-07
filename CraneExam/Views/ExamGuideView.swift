import SwiftUI

/// クレーン試験の総合解説（ホームから開く）。配点・合格基準・学び方。
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
                    overviewCard
                    scoringCard
                    passCard
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
                body("クレーンを安全に運転するための国家試験です。学科試験は **全4科目・合計40問** で、5つの選択肢から誤り（または正しいもの）を1つ選ぶ **五肢択一式** です。")
                body("このアプリの「クレーン限定」では、デリックに関する問題は出題範囲から除かれます。")
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
                bullet("**各科目で 40% 以上**（1科目でも40%未満だと不合格）")
                bullet("**4科目の合計で 60% 以上**")
                Text("配点が科目で違うため、「40問中24問正解」で単純に判断できません。苦手科目を作らないことが大切です。")
                    .font(.system(size: 12)).foregroundColor(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true).padding(.top, 2)
            }
        }
    }

    private var flowCard: some View {
        Card(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("合格までの学び方", "figure.walk")
                step("1", "教材で理解する", "「学科」タブの教材で、全4章をやさしい解説と図で学ぶ。")
                step("2", "用語を確かめる", "「学科」タブの用語で、重要用語を図つきで確認。")
                step("3", "模試で力試し", "「模試」タブで本番形式に挑戦。各40問・40分が目安。")
                step("4", "弱点を復習", "「成績」タブで分野別の到達度と、間違えた問題を見直す。")
            }
        }
    }

    private var linksCard: some View {
        Card(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("公式・参考リンク", "link")
                linkRow("公益財団法人 安全衛生技術試験協会（公式）", "https://www.exam.or.jp/")
                linkRow("クレーン・デリック運転士 過去問（参考）", "https://cranederrick.kakomonn.com/")
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
