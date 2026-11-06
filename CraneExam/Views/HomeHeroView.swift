import SwiftUI
import ImageIO
import UIKit

enum HomeStyle {
    static let teal = Color(Theme.uiDyn(0x95D5CA, 0x286D70))
    static let tealFill = Color(Theme.uiDyn(0x203D42, 0xE8F3F0))
    static let gold = Color(hex: 0xF1BC61)
    static let ink = Color(hex: 0x19354A)
}

/// Downsample large originals; eight full-resolution bitmap decodes must not linger in the picker.
private enum HomeHeroBitmap {
    static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 32 * 1024 * 1024
        return cache
    }()
    static func image(_ hero: HomeHero, revision: Int, pixels: Int) -> UIImage? {
        let key = "\(hero.imageName):\(revision):\(pixels)" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let path = ContentOTA.imagePath(name: hero.imageName),
              let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
              let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: pixels,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { return nil }
        let image = UIImage(cgImage: cg)
        cache.setObject(image, forKey: key, cost: cg.bytesPerRow * cg.height)
        return image
    }
}

struct HomeHeroArtwork: View {
    let hero: HomeHero
    var pixels = 1200
    @EnvironmentObject private var store: ExamStore
    var body: some View {
        Group {
            if let image = HomeHeroBitmap.image(hero, revision: store.contentRevision, pixels: pixels) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image("Hero").resizable().scaledToFill()
            }
        }.accessibilityHidden(true)
    }
}

struct HomeHeroPicker: View {
    @EnvironmentObject private var store: ExamStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @AppStorage(HomeHeroCatalog.preferenceKey) private var savedID = ""
    @State private var previewID = "existing"
    private var catalog: HomeHeroCatalog { store.homeHeroes }
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 1 : 2)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("好きな景色で、学びを続けよう。")
                        .font(.subheadline).foregroundColor(Theme.muted)
                    preview
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(catalog.heroes) { hero in
                            choice(id: hero.id, title: hero.title, subtitle: hero.subtitle, hero: hero)
                        }
                        choice(id: HomeHeroCatalog.noneID, title: "画像なし", subtitle: "学習に集中", hero: nil)
                    }
                    Text("ライト／ダークは、設定した外観に合わせます。")
                        .font(.footnote).foregroundColor(Theme.muted)
                }.padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("ホームの背景").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").frame(width: 44, height: 44)
                    }.accessibilityLabel("変更せずに閉じる")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    savedID = catalog.resolvedID(previewID)
                    dismiss()
                } label: {
                    Label("この背景にする", systemImage: "checkmark")
                        .font(.headline).foregroundColor(HomeStyle.ink)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(HomeStyle.gold).clipShape(RoundedRectangle(cornerRadius: 12))
                }.buttonStyle(.plain).padding(16).background(Theme.bg)
            }
        }
        .onAppear { previewID = catalog.resolvedID(savedID); store.cancelPendingReview() }
        .onChange(of: catalog) { value in previewID = value.resolvedID(previewID) }
    }

    private var preview: some View {
        ZStack(alignment: .bottomLeading) {
            if let hero = catalog.hero(for: previewID) {
                GeometryReader { geo in
                    HomeHeroArtwork(hero: hero).frame(width: geo.size.width, height: geo.size.height).clipped()
                }
                LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .top, endPoint: .bottom)
            } else { Theme.card2 }
            Text("今日の一歩が、\n現場の自信になる。")
                .font(.title3.bold()).foregroundColor(previewID == HomeHeroCatalog.noneID ? Theme.fg : .white)
                .padding(18)
        }
        .frame(minHeight: typeSize.isAccessibilitySize ? 260 : 168)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel("選択中の背景：\(catalog.hero(for: previewID)?.title ?? "画像なし")")
    }

    private func choice(id: String, title: String, subtitle: String, hero: HomeHero?) -> some View {
        let selected = catalog.resolvedID(previewID) == id
        return Button { previewID = id } label: {
            VStack(alignment: .leading, spacing: 0) {
                GeometryReader { geo in
                    if let hero {
                        HomeHeroArtwork(hero: hero, pixels: 480)
                            .frame(width: geo.size.width, height: 88).clipped()
                    } else {
                        Theme.card2.overlay(Image(systemName: "book").font(.title2).foregroundColor(Theme.muted))
                    }
                }.frame(height: 88)
                HStack(alignment: .top, spacing: 6) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title).font(.subheadline.bold()).foregroundColor(Theme.fg)
                        Text(subtitle).font(.caption).foregroundColor(Theme.muted)
                    }.fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selected ? HomeStyle.teal : Theme.muted)
                }.padding(12)
            }
            .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? HomeStyle.teal : Theme.line,
                                                             lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain).accessibilityLabel("\(title)、\(subtitle)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
