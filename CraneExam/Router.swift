import SwiftUI

/// タブ切り替えの共有状態（ホームのカードから各タブへ移動するため）
final class Router: ObservableObject {
    @Published var tab: Int = 0        // 0:ホーム 1:学科 2:成績 3:マイノート 4:設定
    @Published var studySeg: Int = 0   // 0:模擬試験 1:分野別 2:教材
    @Published var noteSeg: Int = 0     // 0:間違えた 1:ブックマーク 2:メモ
}
