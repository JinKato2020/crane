"""One-time source migration from the reviewed home design."""
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def edit(name, old, new):
    path = ROOT/name
    text = path.read_text(encoding='utf-8')
    assert old in text, (name, old[:100])
    path.write_text(text.replace(old, new), encoding='utf-8', newline='\n')

path = ROOT/'CraneExam/Views/HomeView.swift'
old = path.read_text(encoding='utf-8')
growth = old[old.index('    // 成長レーダー'):old.index('    // ホーム最下部')]
growth = growth.replace('$0.pct <= 40', '$0.pct < 40')
growth = growth.replace('!weak && store.accuracy >= 60', '!weak && store.results.reduce(0) { $0 + $1.examScore } >= store.results.count * 60')
growth = growth.replace('40%以下', '40%未満')
tail = old[old.index('/// 分野別正答率のレーダー。'):]
tail = tail.replace('private struct ExamDateSheet:', 'struct ExamDateSheet:')
path.write_text('''import SwiftUI

/// Detailed scores remain available from Home, without crowding its learning actions.
struct HomeProgressView: View {
    @EnvironmentObject private var store: ExamStore
    @Environment(\\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView { growthCard.padding(16) }
                .background(Theme.bg.ignoresSafeArea())
                .navigationTitle("学習の成績").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("閉じる") { dismiss() } } }
        }
    }
''' + growth + '}\n\n' + tail, encoding='utf-8', newline='\n')

edit('CraneExam/Views/TextbookView.swift', '                FeedbackInvitationCard()\n', '')
edit('CraneExam/Views/MockExamView.swift', '                    FeedbackInvitationCard()\n', '')
edit('CraneExam/Views/GlossaryView.swift', '                    FeedbackInvitationCard()\n', '')
edit('CraneExam/Views/GlossaryView.swift', '.trackStudyCompletion()', '.trackStudyCompletion(kind: .glossary)')
edit('CraneExam/Views/GlossaryView.swift',
     '.navigationTitle("第\\(chapter.id)章 用語").navigationBarTitleDisplayMode(.inline)',
     '''.navigationTitle("第\\(chapter.id)章 用語").navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.rememberStudy(StudyPlace(kind: .glossary, title: "第\\(chapter.id)章の用語", chapterID: chapter.id))
        }''')
edit('CraneExam/Views/TextbookView.swift',
     '''        .trackStudyCompletion()
    }
}

/// 1節ぶん''',
     '''        .onAppear { rememberSection() }
        .onChange(of: index) { _ in rememberSection() }
        .trackStudyCompletion(kind: .textbook)
    }

    private func rememberSection() {
        guard secs.indices.contains(index) else { return }
        let section = secs[index]
        store.rememberStudy(StudyPlace(kind: .textbook, title: section.title,
                                       chapterID: chapter.id, sectionID: section.id))
    }
}

/// 1節ぶん''')
edit('CraneExam/Views/QuizView.swift', '.trackStudyCompletion()', '.trackStudyCompletion(kind: .exam)')
edit('CraneExam/Views/QuizView.swift',
     '''        .onAppear {
            if clock == nil''',
     '''        .onAppear {
            store.rememberStudy(StudyPlace(kind: .exam, title: "模擬試験 第\\(exam.round)回", examRound: exam.round))
            if clock == nil''')
print('Home scores preserved; learning destinations and study categories connected.')
