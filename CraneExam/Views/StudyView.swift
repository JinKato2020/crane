import SwiftUI

struct StudyView: View {
    @EnvironmentObject var store: ExamStore
    @EnvironmentObject var router: Router

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("", selection: $router.studySeg) {
                        Text("模擬試験").tag(0)
                        Text("分野別").tag(1)
                    }
                    .pickerStyle(.segmented)

                    if router.studySeg == 0 {
                        mockList
                    } else {
                        fieldList
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("学科")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // 模擬試験リスト（8回）
    private var mockList: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHead(title: "公表形式 模擬試験(全8回)", trailing: "各40問")
            ForEach(store.exams) { exam in
                NavigationLink {
                    QuizView(exam: exam, mode: .full)
                } label: {
                    examRow(exam)
                }
                .buttonStyle(.plain)
            }
            if store.exams.isEmpty {
                Text("問題データを読み込めませんでした。").foregroundColor(Theme.muted).font(.system(size: 13)).padding()
            }
        }
    }

    private func examRow(_ exam: Exam) -> some View {
        let r = store.latestResult(round: exam.round)
        return HStack(spacing: 13) {
            VStack(spacing: 1) {
                Text("\(exam.round)").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(Theme.accent2)
                Text("第\(exam.round)回").font(.system(size: 8.5)).foregroundColor(Theme.muted)
            }
            .frame(width: 46, height: 46)
            .background(Theme.raise).clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text("模擬試験 第\(exam.round)回").font(.system(size: 14, weight: .bold)).foregroundColor(Theme.fg)
                HStack(spacing: 10) {
                    Text("全\(exam.questions.count)問")
                    Text("制限 40分")
                }.font(.system(size: 11)).foregroundColor(Theme.muted)
            }
            Spacer()
            if let r = r {
                Pill(text: "受験済 \(r.percent)点", fg: Theme.good, bg: Theme.good.opacity(0.18))
            } else {
                Pill(text: "未受験", fg: Color(hex: 0x5AA9FF), bg: Color(hex: 0x5AA9FF).opacity(0.18))
            }
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.faint)
        }
        .padding(13)
        .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
    }

    // 分野別
    private var fieldList: some View {
        let acc = store.subjectAccuracy()
        return VStack(alignment: .leading, spacing: 10) {
            SectionHead(title: "分野別の到達度", trailing: "全結果の合算")
            Card {
                VStack(spacing: 2) {
                    ForEach(acc, id: \.name) { item in
                        BarRow(name: subjectShort(item.name), pct: item.pct)
                    }
                }
            }
            Text("模擬試験を受けると分野別の正答率がここに反映されます。")
                .font(.system(size: 11.5)).foregroundColor(Theme.faint)
                .padding(.horizontal, 2)
        }
    }
}
