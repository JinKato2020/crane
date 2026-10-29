import Foundation

/// アプリと同じCodableモデル・解決関数をコンパイルし、全データと後方互換を検証。
@main
struct ReferenceVerification {
    static func main() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1])
        let decoder = JSONDecoder()
        let textbook = try decoder.decode(Textbook.self, from: Data(contentsOf: root.appendingPathComponent("textbook.json")))
        let exams = try decoder.decode([Exam].self, from: Data(contentsOf: root.appendingPathComponent("exams.json")))
        let sections = Dictionary(uniqueKeysWithValues: textbook.chapters.flatMap(\.sections).map { ($0.id, $0) })
        var count = 0
        for exam in exams {
            precondition(exam.questions.count == 40)
            for question in exam.questions {
                precondition(question.choices.count == 5)
                precondition((1...5).contains(question.answer))
                precondition(!question.textbookReferences.isEmpty)
                for ref in question.textbookReferences {
                    guard let section = sections[ref.section],
                          let index = TextbookReferenceResolver.index(in: section, for: ref) else {
                        fatalError("参照解決失敗: \(exam.round)-\(question.no) \(ref.id)")
                    }
                    precondition(section.blocks[index].id == ref.blockID)
                    count += 1
                }
            }
        }
        let fixture = #"{"id":"fixture","title":"検証","blocks":[{"type":"p","text":"先に同名語がある"},{"type":"table","id":"table-id","headers":["見出し"],"rows":[["表の固有語"]]},{"type":"ul","items":["箇条書きの固有語"]},{"type":"sub","id":"stable-id","text":"変更後の見出し"}]}"#
        let section = try decoder.decode(TBSection.self, from: Data(fixture.utf8))
        func ref(_ json: String) throws -> TextRef { try decoder.decode(TextRef.self, from: Data(json.utf8)) }
        func expect(_ json: String, _ expected: Int?) throws {
            let actual = TextbookReferenceResolver.index(in: section, for: try ref(json))
            precondition(actual == expected)
        }
        try expect(#"{"section":"fixture","blockID":"stable-id","anchor":"同名語"}"#, 3)
        try expect(#"{"section":"fixture","anchor":"表の固有語"}"#, 1)
        try expect(#"{"section":"fixture","anchor":"箇条書きの固有語"}"#, 2)
        try expect(#"{"section":"fixture","anchor":"見出し"}"#, 3)
        try expect(#"{"section":"fixture","blockID":"unknown","anchor":"表の固有語"}"#, 1)
        try expect(#"{"section":"fixture","anchor":"不存在"}"#, nil)
        let legacy = #"{"no":1,"subject":"力学","text":"旧版","choices":["1","2","3","4","5"],"answer":1,"explanation":"説明","ref":{"section":"fixture","anchor":"表の固有語"}}"#
        let question = try decoder.decode(Question.self, from: Data(legacy.utf8))
        precondition(question.textbookReferences.count == 1)
        let emptyRefs = String(legacy.dropLast()) + #", "refs":[]}"#
        let empty = try decoder.decode(Question.self, from: Data(emptyRefs.utf8))
        precondition(empty.textbookReferences.count == 1)
        print("PASS: 480 questions / \(count) references; stable IDs, table/list fallback and legacy data")
    }
}
