import SwiftUI

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

enum Theme {
    static let bg     = Color(hex: 0x0C0E12)
    static let panel  = Color(hex: 0x14171E)
    static let card   = Color(hex: 0x191D25)
    static let card2  = Color(hex: 0x1F242E)
    static let raise  = Color(hex: 0x232936)
    static let line   = Color(hex: 0x2A303C)
    static let fg     = Color(hex: 0xEEF1F6)
    static let muted  = Color(hex: 0x9AA4B4)
    static let faint  = Color(hex: 0x6B7483)
    static let accent = Color(hex: 0xF6A425)
    static let accent2 = Color(hex: 0xFFCB5B)
    static let good   = Color(hex: 0x3EC27A)
    static let warn   = Color(hex: 0xFF6A52)

    static let gold = LinearGradient(
        colors: [accent, accent2], startPoint: .leading, endPoint: .trailing)

    /// 分野の表示色
    static func subjectColor(_ s: String) -> Color {
        switch s {
        case "関係法令": return accent
        case "クレーンに関する知識": return Color(hex: 0x5AA9FF)
        case "原動機・電気": return good
        case "力学": return Color(hex: 0xC08BFF)
        default: return Color(hex: 0xFF8F6B)
        }
    }
}
