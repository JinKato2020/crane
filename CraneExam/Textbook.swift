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
}
