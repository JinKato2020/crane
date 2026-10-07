import SwiftUI

/// タブ切り替えの共有状態（ホームのカードから各タブへ移動するため）
final class Router: ObservableObject {
    @Published var tab: Int = 0        // 0:ホーム 1:学科 2:模試 3:成績 4:設定
    @Published var studySeg: Int = 0   // 学科: 0:教材 1:用語
    @Published var noteSeg: Int = 0    // 成績内のマイノート: 0:間違えた 1:ブックマーク 2:メモ
}
