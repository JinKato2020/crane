import SwiftUI

/// タブ切り替えの共有状態（ホームのカードから各タブへ移動するため）
final class Router: ObservableObject {
    @Published var tab: Int = 0        // 0:ホーム 1:教材 2:模試・成績 3:用語 4:設定
}
