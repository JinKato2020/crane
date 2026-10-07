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
    let type: String
    let text: String?
    let items: [String]?
    let headers: [String]?
    let rows: [[String]]?
    let asset: String?       // 画像(img)のファイル名(拡張子なし)
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
