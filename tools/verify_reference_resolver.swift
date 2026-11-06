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
        // Glossary data: optional additions, stable IDs, real destinations and search.
        let oldTerm = try decoder.decode(TBTerm.self, from: Data(#"{"term":"旧用語","def":"以前の説明","img":"legacy"}"#.utf8))
        precondition(oldTerm.id == "旧用語" && oldTerm.introduction == "以前の説明")
        precondition(oldTerm.illustrations.first?.file == "legacy.png")
        let plainOldTerm = try decoder.decode(TBTerm.self, from: Data(#"{"term":"図なし","def":"説明"}"#.utf8))
        precondition(plainOldTerm.illustrations.isEmpty && !plainOldTerm.hasDetails)
        var glossaryRefs = 0
        for chapter in textbook.chapters {
            var figureNames = Set<String>()
            for term in chapter.glossary ?? [] {
                precondition(term.id == term.term && !term.def.isEmpty)
                precondition(term.matches(term.term) && term.matches(" 　"))
                if let reading = term.reading { precondition(term.matches(reading)) }
                for alias in term.aliases ?? [] { precondition(term.matches(alias)) }
                if let comparison = term.comparison {
                    precondition(comparison.headers.count == 2)
                    precondition(comparison.rows.allSatisfy { $0.count == comparison.headers.count })
                }
                for figure in term.illustrations {
                    precondition(figureNames.insert(figure.file).inserted, "同章で図が重複: \(figure.file)")
                    precondition(FileManager.default.fileExists(atPath: root.appendingPathComponent("images/\(figure.file)").path))
                }
                for reference in term.references ?? [] {
                    guard let target = sections[reference.section],
                          let index = TextbookReferenceResolver.index(in: target, for: reference) else {
                        fatalError("用語の参照失敗: \(term.term)")
                    }
                    precondition(target.blocks[index].id == reference.blockID)
                    glossaryRefs += 1
                }
            }
        }
        let terms = textbook.chapters.flatMap { $0.glossary ?? [] }
        let rotor = terms.first { $0.term.contains("かご形／巻線形") }!
        precondition(rotor.matches("かご型") && rotor.matches("カゴガタ"))
        precondition(rotor.matches("かごがた") && rotor.matches("ｶｺﾞｶﾞﾀ"))
        precondition(rotor.matches("巻線形 すべり") && !rotor.matches("巻線形 存在しない語句"))
        precondition(TBTerm.searchKey("ＶＶＶＦ") == TBTerm.searchKey("vvvf"))
        print("PASS: glossary references \(glossaryRefs), legacy decoding, unique figures, kana/alias/AND search")
        print("PASS: 480 questions / \(count) references; stable IDs, table/list fallback and legacy data")
    }
}
