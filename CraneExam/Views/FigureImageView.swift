import SwiftUI
import UIKit

/// 図アセットをバンドルから読む
func loadFigureUIImage(_ name: String) -> UIImage? {
    guard let path = ContentOTA.imagePath(name: name) else { return nil }
    return UIImage(contentsOfFile: path)
}

/// 図を表示する共有部品。ラベルを重ね、タップで全画面ズーム。教材・用語集の両方で使う。
struct FigureImageView: View {
    let assetName: String
    var labels: [TBLabel] = []
    var legend: [String] = []
    var caption: String? = nil
    var thumbMaxHeight: CGFloat = 150
    /// 凡例をこの部品の下に出すか(教材は別で出すので false のことも)
    var showLegend: Bool = true

    @State private var zooming = false

    var body: some View {
        if let ui = loadFigureUIImage(assetName) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .bottomTrailing) {
                    labeledImage(ui, fontSize: 8.5)
                        .frame(maxWidth: .infinity, maxHeight: thumbMaxHeight)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1))

                    // 拡大ヒント
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right").font(.system(size: 9, weight: .bold))
                        Text("タップで拡大").font(.system(size: 9, weight: .bold))
                    }
                    .padding(.horizontal, 7).padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.6)))
                    .foregroundColor(.white)
                    .padding(8)
                }
                .contentShape(Rectangle())
                .onTapGesture { zooming = true }

                if showLegend, !legend.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(legend.enumerated()), id: \.offset) { _, s in
                            Text("・" + s).font(.system(size: 11)).foregroundColor(Theme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $zooming) {
                ZoomableFigureView(image: ui, labels: labels, caption: caption, legend: legend) { zooming = false }
            }
        } else {
            RoundedRectangle(cornerRadius: 10).fill(Theme.card2)
                .frame(height: 110)
                .overlay(Text("（図を準備中）").font(.system(size: 12)).foregroundColor(Theme.faint))
        }
    }

    /// 画像＋ラベル重ね
    @ViewBuilder
    private func labeledImage(_ ui: UIImage, fontSize: CGFloat) -> some View {
        Image(uiImage: ui).resizable().scaledToFit()
            .overlay(
                GeometryReader { g in
                    ForEach(Array(labels.enumerated()), id: \.offset) { _, lb in
                        Text(lb.text)
                            .font(.system(size: fontSize, weight: .bold))
                            .padding(.horizontal, fontSize * 0.35).padding(.vertical, fontSize * 0.12)
                            .background(RoundedRectangle(cornerRadius: 3).fill(Color.black.opacity(0.66)))
                            .foregroundColor(.white)
                            .fixedSize()
                            .position(x: lb.x * g.size.width, y: lb.y * g.size.height)
                    }
                }
            )
    }
}

/// 全画面でピンチ拡大・ドラッグ移動できる図ビューア
struct ZoomableFigureView: View {
    let image: UIImage
    var labels: [TBLabel] = []
    var caption: String? = nil
    var legend: [String] = []
    let onClose: () -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private func fitted(_ container: CGSize) -> CGSize {
        let a = max(0.01, image.size.width / image.size.height)
        if container.width / container.height > a {
            let h = container.height; return CGSize(width: h * a, height: h)
        } else {
            let w = container.width; return CGSize(width: w, height: w / a)
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                let fit = fitted(geo.size)
                ZStack {
                    Image(uiImage: image).resizable()
                        .frame(width: fit.width, height: fit.height)
                        .background(Color.white)
                    ForEach(Array(labels.enumerated()), id: \.offset) { _, lb in
                        Text(lb.text)
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color.black.opacity(0.72)))
                            .foregroundColor(.white)
                            .fixedSize()
                            .position(x: lb.x * fit.width, y: lb.y * fit.height)
                    }
                }
                .frame(width: fit.width, height: fit.height)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { v in scale = min(max(lastScale * v, 1), 6) }
                        .onEnded { _ in lastScale = scale; if scale <= 1 { withAnimation { offset = .zero; lastOffset = .zero } } }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { v in
                            guard scale > 1 else { return }
                            offset = CGSize(width: lastOffset.width + v.translation.width,
                                            height: lastOffset.height + v.translation.height)
                        }
                        .onEnded { _ in lastOffset = offset }
                )
                .onTapGesture(count: 2) {
                    withAnimation {
                        if scale > 1 { scale = 1; lastScale = 1; offset = .zero; lastOffset = .zero }
                        else { scale = 2.5; lastScale = 2.5 }
                    }
                }
            }

            // キャプション・凡例(下部)
            VStack {
                Spacer()
                if caption != nil || !legend.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        if let c = caption { Text("図：\(c)").font(.system(size: 12, weight: .bold)).foregroundColor(.white) }
                        ForEach(Array(legend.enumerated()), id: \.offset) { _, s in
                            Text("・" + s).font(.system(size: 11)).foregroundColor(.white.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.black.opacity(0.55))
                }
            }
            .ignoresSafeArea(edges: .bottom)

            // 閉じる・操作ヒント(上部)
            VStack {
                HStack {
                    Text("ピンチ/ダブルタップで拡大")
                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.15)))
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30)).foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal, 16).padding(.top, 10)
                Spacer()
            }
        }
    }
}
