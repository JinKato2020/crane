import Foundation

/// 教材(読んで学ぶテキスト)のデータ構造
struct Textbook: Codable {
    let chapters: [TBChapter]
}

/// 1つの章
struct TBChapter: Codable, Identifiable {
    let id: Int
    let title: String
    let subject: String      // 対応する試験科目
    let summary: String      // 一覧に出す1行説明
    let sections: [TBSection]
    let glossary: [TBTerm]?  // 章の重要用語(用語集カードで使用)
}

/// 用語集の1項目
struct TBTerm: Codable, Identifiable {
    let term: String
    let def: String
    let img: String?     // 対応する図(あれば)
    // Optional fields keep previously downloaded / bundled glossary data readable.
    let displayTerm: String?
    let reading: String?
    let summary: String?
    let category: String?
    let points: [String]?
    let example: String?
    let comparison: TBTermComparison?
    let aliases: [String]?
    let figures: [TBTermFigure]?
    let references: [TextRef]?
    var id: String { term }
    var title: String { displayTerm ?? term }
    var introduction: String { summary ?? def }
    var illustrations: [TBTermFigure] {
        if let figures = figures { return figures }
        return img.map { [TBTermFigure(file: $0 + ".png", caption: nil)] } ?? []
    }
    var hasDetails: Bool {
        !(points ?? []).isEmpty || example != nil || comparison != nil || !illustrations.isEmpty || !(references ?? []).isEmpty
    }

    /// AND search: kanji, kana readings, common alternate names and explanations.
    func matches(_ query: String) -> Bool {
        let words = Self.searchKey(query).split(whereSeparator: { $0.isWhitespace })
        if words.isEmpty { return true }
        let values = [term, title, reading ?? "", summary ?? "", def, category ?? "", example ?? ""]
            + (points ?? []) + (aliases ?? [])
        let haystack = Self.searchKey(values.joined(separator: " "))
        return words.allSatisfy { haystack.contains($0) }
    }

    static func searchKey(_ value: String) -> String {
        let folded = value.folding(options: [.caseInsensitive, .widthInsensitive], locale: Locale(identifier: "ja_JP"))
        return (folded.applyingTransform(.hiraganaToKatakana, reverse: false) ?? folded).lowercased()
    }
}

struct TBTermFigure: Codable, Identifiable {
    let file: String
    let caption: String?
    var id: String { file }
    var isSVG: Bool { file.lowercased().hasSuffix(".svg") }
    var assetName: String { (file as NSString).deletingPathExtension }
}

/// Short two-column comparisons wrap with Dynamic Type instead of shrinking text.
struct TBTermComparison: Codable {
    let title: String
    let headers: [String]
    let rows: [[String]]
}

/// 章の中の1節
struct TBSection: Codable, Identifiable {
    let id: String
    let title: String
    let blocks: [TBBlock]
}

/// 本文を構成するブロック
/// type: "sub"(小見出し) / "p"(本文) / "ul"(箇条書き) / "table"(表) / "fig"(図・等幅) / "point"(ここが出る)
struct TBBlock: Codable {
    let id: String?         // 教材参照用。既存データでは省略可
    let style: String?      // lead / tip / caution / numbers / figure / question / answer / reference
    let quizTerms: [String]? // このブロックで思い出す重要語句・数値（本文は変更しない）
    let type: String
    let text: String?
    let items: [String]?
    let headers: [String]?
    let rows: [[String]]?
    let asset: String?       // 画像(img)のファイル名(拡張子なし)
    let file: String?        // SVG図(svg)のファイル名(拡張子つき 例 2-1_xxx.svg)
    let caption: String?     // 画像の説明
    let labels: [TBLabel]?   // 図に重ねる文字ラベル
    let legend: [String]?    // 図の下に出す凡例(説明)
}

/// 図に重ねる1つのラベル(x,yは0〜1の相対位置)
struct TBLabel: Codable {
    let x: Double
    let y: Double
    let text: String
}

/// UIと検証スクリプトが共用する教材参照の解決。固定IDがあれば最優先する。
enum TextbookReferenceResolver {
    static func index(in section: TBSection, for ref: TextRef) -> Int? {
        if let id = ref.blockID,
           let index = section.blocks.firstIndex(where: { $0.id == id }) { return index }
        guard let anchor = ref.anchor, !anchor.isEmpty else { return nil }
        if let index = section.blocks.firstIndex(where: {
            $0.type == "sub" && ($0.text ?? "").contains(anchor)
        }) { return index }
        return section.blocks.firstIndex { block in
            let values = [block.text ?? "", block.caption ?? ""]
                + (block.items ?? []) + (block.headers ?? []) + (block.rows ?? []).flatMap { $0 }
            return values.contains { $0.contains(anchor) }
        }
    }
}

/// 図アセット1枚ぶんの付随情報(教材のimgブロックから集約。用語集で同じ図にラベルを重ねるのに使う)
struct TBFigureInfo {
    let labels: [TBLabel]
    let legend: [String]
    let caption: String?
}
