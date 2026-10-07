import SwiftUI
import UIKit

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

extension UIColor {
    convenience init(hex: UInt, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: alpha
        )
    }
}

enum Theme {
    /// ダーク/ライトで自動的に切り替わる色(darkの値, lightの値)
    private static func dyn(_ dark: UInt, _ light: UInt) -> Color {
        Color(UIColor { tc in UIColor(hex: tc.userInterfaceStyle == .dark ? dark : light) })
    }
    /// UIKit外観(タブバー等)用の動的UIColor
    static func uiDyn(_ dark: UInt, _ light: UInt) -> UIColor {
        UIColor { tc in UIColor(hex: tc.userInterfaceStyle == .dark ? dark : light) }
    }

    static let bg      = dyn(0x0C0E12, 0xF4F6F9)
    static let panel   = dyn(0x14171E, 0xFFFFFF)
    static let card    = dyn(0x191D25, 0xFFFFFF)
    static let card2   = dyn(0x1F242E, 0xEFF2F6)
    static let raise   = dyn(0x232936, 0xE7EBF1)
    static let line    = dyn(0x2A303C, 0xD6DBE3)
    static let fg      = dyn(0xEEF1F6, 0x1A1D22)
    static let muted   = dyn(0x9AA4B4, 0x5A6472)
    static let faint   = dyn(0x6B7483, 0x8A93A1)
    static let accent  = dyn(0xF6A425, 0xE08A00)
    static let accent2 = dyn(0xFFCB5B, 0xB97B08)
    static let good    = dyn(0x3EC27A, 0x1E9E57)
    static let warn    = dyn(0xFF6A52, 0xDE432A)

    /// ブランドのゴールド(濃色文字をのせる前提なので明暗共通)
    static let gold = LinearGradient(
        colors: [Color(hex: 0xF6A425), Color(hex: 0xFFCB5B)],
        startPoint: .leading, endPoint: .trailing)

    /// 分野の表示色
    static func subjectColor(_ s: String) -> Color {
        switch s {
        case "関係法令": return accent
        case "クレーンに関する知識": return dyn(0x5AA9FF, 0x2E7BE0)
        case "原動機・電気": return good
        case "力学": return dyn(0xC08BFF, 0x8A4FE0)
        default: return dyn(0xFF8F6B, 0xE0613A)
        }
    }
}
