import SwiftUI

/// 枠付きカード
struct Card<Content: View>: View {
    var padding: CGFloat = 15
    var radius: CGFloat = 14
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }
}

/// 円グラフ（達成度・得点）
struct Ring: View {
    var progress: Double
    var size: CGFloat = 92
    var line: CGFloat = 9
    var label: String
    var sub: String
    var body: some View {
        ZStack {
            Circle().stroke(Theme.raise, lineWidth: line)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(Theme.gold, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text(label)
                    .font(.system(size: size * 0.30, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.fg)
                Text(sub)
                    .font(.system(size: max(9, size * 0.11)))
                    .foregroundColor(Theme.muted)
            }
        }
        .frame(width: size, height: size)
    }
}

/// 分野別の横棒
struct BarRow: View {
    var name: String
    var pct: Int
    var body: some View {
        HStack(spacing: 12) {
            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.fg)
                .frame(width: 70, alignment: .leading)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.raise)
                    Capsule().fill(Theme.gold)
                        .frame(width: max(6, g.size.width * CGFloat(pct) / 100))
                }
            }
            .frame(height: 8)
            Text("\(pct)%")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.accent2)
                .frame(width: 42, alignment: .trailing)
        }
        .frame(height: 24)
    }
}

/// 小さなラベル
struct Pill: View {
    var text: String
    var fg: Color
    var bg: Color
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(bg).foregroundColor(fg)
            .clipShape(Capsule())
    }
}

/// セクション見出し
struct SectionHead: View {
    var title: String
    var trailing: String? = nil
    var body: some View {
        HStack {
            Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(Theme.fg)
            Spacer()
            if let t = trailing {
                Text(t).font(.system(size: 12)).foregroundColor(Theme.muted)
            }
        }
    }
}
