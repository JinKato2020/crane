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
    var id: String { term }
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
    let style: String?      // lead / tip / caution / numbers。既存の型を保った表示指定
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
