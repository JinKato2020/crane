import SwiftUI
import WebKit

/// SVG図(3D技術イラスト)を表示する部品。
/// SwiftUI/UIKitはSVGを直接描けないため、WKWebViewで描画する(PDFと同じ見え方)。
/// 図中の日本語文字・寸法線はSVG内に焼き込まれているので、ラベル重ねは不要。
/// タップで全画面ズーム(ピンチ/ダブルタップ)。

/// figm*.svg のファイル名(拡張子つき/なしどちらでも)から SVG 文字列を読む。
func loadFigureSVGString(_ file: String) -> String? {
    let name = (file as NSString).deletingPathExtension
    guard let p = ContentOTA.svgPath(name: name) else { return nil }
    return try? String(contentsOfFile: p, encoding: .utf8)
}

/// SVGの viewBox から アスペクト比(幅/高さ) を取り出す。取れなければ nil。
func svgAspectRatio(_ svg: String) -> CGFloat? {
    guard let r = svg.range(of: "viewBox", options: .caseInsensitive) else { return nil }
    let tail = svg[r.upperBound...]
    guard let q1 = tail.firstIndex(where: { $0 == "\"" || $0 == "'" }) else { return nil }
    let afterQ = tail[tail.index(after: q1)...]
    guard let q2 = afterQ.firstIndex(where: { $0 == "\"" || $0 == "'" }) else { return nil }
    let nums = afterQ[..<q2]
        .split(whereSeparator: { $0 == " " || $0 == "," })
        .compactMap { Double($0) }
    guard nums.count == 4, nums[3] > 0 else { return nil }
    return CGFloat(nums[2] / nums[3])
}

/// SVG文字列を WKWebView に埋め込んで描画する。scalable=true のときピンチ拡大できる。
struct SVGWebView: UIViewRepresentable {
    let svg: String
    var scalable: Bool = false

    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        wv.scrollView.isScrollEnabled = scalable
        wv.scrollView.bouncesZoom = scalable
        wv.scrollView.minimumZoomScale = 1
        wv.scrollView.maximumZoomScale = scalable ? 6 : 1
        wv.isOpaque = false
        wv.backgroundColor = .white
        wv.scrollView.backgroundColor = .white
        wv.isUserInteractionEnabled = scalable   // 一覧ではタップを親(ズーム起動)へ通す
        return wv
    }

    func updateUIView(_ wv: WKWebView, context: Context) {
        let vp = scalable ? "initial-scale=1,user-scalable=yes,maximum-scale=6"
                          : "initial-scale=1,user-scalable=no"
        let html = """
        <!doctype html><html><head><meta charset='utf-8'>
        <meta name='viewport' content='width=device-width,\(vp)'>
        <style>html,body{margin:0;padding:0;background:#fff}
        .wrap{display:flex;justify-content:center;align-items:center;min-height:100vh;box-sizing:border-box}
        svg{max-width:100%;height:auto;display:block}</style></head>
        <body><div class='wrap'>\(svg)</div></body></html>
        """
        wv.loadHTMLString(html, baseURL: nil)
    }
}

/// 教材本文で使うSVG図(サムネイル+タップ拡大)。
struct SVGFigureView: View {
    let file: String
    var caption: String? = nil
    var thumbMaxHeight: CGFloat = 320

    @State private var zooming = false

    var body: some View {
        if let svg = loadFigureSVGString(file) {
            let ar = svgAspectRatio(svg) ?? 1.6
            SVGWebView(svg: svg)
                .aspectRatio(ar, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: thumbMaxHeight)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1))
                .overlay(alignment: .bottomTrailing) {
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
                .fullScreenCover(isPresented: $zooming) {
                    ZoomableSVGView(svg: svg, caption: caption) { zooming = false }
                }
        } else {
            RoundedRectangle(cornerRadius: 10).fill(Theme.card2)
                .frame(height: 110)
                .overlay(Text("（図を準備中）").font(.system(size: 12)).foregroundColor(Theme.faint))
        }
    }
}

/// 全画面でピンチ拡大できるSVGビューア。
struct ZoomableSVGView: View {
    let svg: String
    var caption: String? = nil
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            SVGWebView(svg: svg, scalable: true)
                .background(Color.white)
                .ignoresSafeArea(edges: .horizontal)

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
                if let c = caption, !c.isEmpty {
                    Text("図：\(c)")
                        .font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color.black.opacity(0.55))
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}
