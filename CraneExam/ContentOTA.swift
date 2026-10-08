import Foundation

/// コンテンツOTA(Over-The-Air更新)。
/// 棚(Cloudflare R2 = https://content.safa-lang.com/crane/)から、変わったファイル(content/*.json)だけ
/// ダウンロードして端末キャッシュへ保存する。読込は「キャッシュがあればそれ、無ければ内蔵(Resources)」。
/// 反映は次回起動、または sync() 直後の再読込(同じ起動中)。
///
/// お手本: CAE `src/data/contentOta.ts`(R2 + _manifest.json + sha256差分)を Swift へ移植。
/// 失敗(通信断など)しても、アプリは内蔵データで必ず動く(壊れない設計)。
enum ContentOTA {
    static let appID = "crane"
    static let baseURL = "https://content.safa-lang.com/\(appID)/"

    // OTA対象のキー → 内蔵(Resources)のファイル名(拡張子なし)
    static let targets: [(key: String, bundledResource: String)] = [
        ("content/exams.json", "exams"),
        ("content/textbook.json", "textbook"),
    ]

    struct Entry: Decodable { let sha256: String; let size: Int? }
    struct Manifest: Decodable { let files: [String: Entry] }

    // 端末のキャッシュ置き場(Caches)
    private static var cacheDir: URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent("\(appID)-content", isDirectory: true)
    }
    private static var shaPath: URL { cacheDir.appendingPathComponent("_shas.json") }
    private static var bundleTagPath: URL { cacheDir.appendingPathComponent("_bundle.tag") }

    /// キー → 安全なローカルファイル名(英数字以外はパーセントエンコード)
    private static func localName(_ key: String) -> String {
        key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
    }

    // MARK: - 同梱(baseline) manifest

    private static func bundledManifest() -> Manifest? {
        guard let url = Bundle.main.url(forResource: "_manifest", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let m = try? JSONDecoder().decode(Manifest.self, from: data) else { return nil }
        return m
    }

    /// 同梱manifestの識別子。ビルドで土台(内蔵データ)が変わると値が変わる。
    /// → 新しいビルドのとき、古いキャッシュを土台に混ぜない判定に使う。
    private static func bundleTag() -> String {
        let files = bundledManifest()?.files ?? [:]
        let s = files.keys.sorted().map { "\($0):\(files[$0]?.sha256 ?? "")" }.joined(separator: "|")
        var h: UInt32 = 5381
        for b in s.utf8 { h = (h &* 33) ^ UInt32(b) }
        return String(h, radix: 16)
    }

    private static func storedBundleTag() -> String {
        (try? String(contentsOf: bundleTagPath, encoding: .utf8)) ?? ""
    }

    // MARK: - 読込(キャッシュ優先・無ければ内蔵)

    /// content/<name>.json のデータを返す。キャッシュ(タグ一致時)→内蔵 の順。
    static func contentData(key: String, bundledResource: String) -> Data? {
        if storedBundleTag() == bundleTag() {
            let f = cacheDir.appendingPathComponent(localName(key))
            if let d = try? Data(contentsOf: f) { return d }
        }
        if let url = Bundle.main.url(forResource: bundledResource, withExtension: "json") {
            return try? Data(contentsOf: url)
        }
        return nil
    }

    // MARK: - 同期(棚の最新を取り込む)

    private static func readShas() -> [String: String] {
        guard let d = try? Data(contentsOf: shaPath),
              let m = try? JSONDecoder().decode([String: String].self, from: d) else { return [:] }
        return m
    }

    /// 今、端末が実際に持っているsha = 同梱(土台) ∪ (タグ一致時のみ)キャッシュ
    private static func effectiveShas(_ cached: [String: String]) -> [String: String] {
        var base: [String: String] = [:]
        for (k, v) in bundledManifest()?.files ?? [:] { base[k] = v.sha256 }
        if storedBundleTag() == bundleTag() {
            for (k, v) in cached { base[k] = v }
        }
        return base
    }

    private static func isOtaTarget(_ key: String) -> Bool { key.hasPrefix("content/") }

    /// 棚のmanifestと差分を取り、変わったファイルだけDLしてキャッシュ保存。更新件数を返す。
    /// 失敗時は 0 を返すだけ(例外は投げない)。
    @discardableResult
    static func sync() async -> Int {
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

        // 目次(_manifest.json)は毎回「最新」を掴む(?t=時刻 + no-store)。
        // 古いCDN/端末キャッシュを掴むと「変化なし」と誤判定して更新されないため。
        let ts = Int(Date().timeIntervalSince1970 * 1000)
        guard let murl = URL(string: baseURL + "_manifest.json?t=\(ts)") else { return 0 }
        var mreq = URLRequest(url: murl, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 8)
        mreq.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        guard let (mdata, mresp) = try? await URLSession.shared.data(for: mreq),
              (mresp as? HTTPURLResponse)?.statusCode == 200,
              let remote = try? JSONDecoder().decode(Manifest.self, from: mdata) else { return 0 }

        var cached = readShas()
        let have = effectiveShas(cached)
        var updated = 0
        for (key, entry) in remote.files where isOtaTarget(key) {
            if have[key] == entry.sha256 { continue }
            // 実ファイルも指紋(sha)を ?v= に付けて古いキャッシュを避ける。
            guard let furl = URL(string: baseURL + key + "?v=" + entry.sha256) else { continue }
            var freq = URLRequest(url: furl, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20)
            freq.setValue("no-store", forHTTPHeaderField: "Cache-Control")
            if let (fdata, fresp) = try? await URLSession.shared.data(for: freq),
               (fresp as? HTTPURLResponse)?.statusCode == 200 {
                let dest = cacheDir.appendingPathComponent(localName(key))
                if (try? fdata.write(to: dest, options: .atomic)) != nil {
                    cached[key] = entry.sha256
                    updated += 1
                }
            }
        }
        if let d = try? JSONEncoder().encode(cached) { try? d.write(to: shaPath, options: .atomic) }
        try? bundleTag().write(to: bundleTagPath, atomically: true, encoding: .utf8)
        return updated
    }
}
