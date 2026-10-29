import Foundation
import CryptoKit

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
    struct Manifest: Decodable {
        let files: [String: Entry]
        let generatedAt: String?
    }

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

    private static func cachedFile(_ key: String) -> URL? {
        guard storedBundleTag() == bundleTag(), readShas()[key] != nil else { return nil }
        let file = cacheDir.appendingPathComponent(localName(key))
        return FileManager.default.fileExists(atPath: file.path) ? file : nil
    }

    // MARK: - 読込(キャッシュ優先・無ければ内蔵)

    /// content/<name>.json のデータを返す。キャッシュ(タグ一致時)→内蔵 の順。
    static func contentData(key: String, bundledResource: String) -> Data? {
        if let f = cachedFile(key), let d = try? Data(contentsOf: f) { return d }
        if let url = Bundle.main.url(forResource: bundledResource, withExtension: "json") {
            return try? Data(contentsOf: url)
        }
        return nil
    }

    /// 図などの画像を「キャッシュ(同梱タグ一致時)優先・無ければ内蔵」で解決してファイルパスを返す。
    /// キー体系: content/images/<name>.<jpg|png>(sync()が content/ 配下として自動DL・キャッシュする)。
    static func imagePath(name: String) -> String? {
        for ext in ["jpg", "png"] {
            if let f = cachedFile("content/images/\(name).\(ext)") { return f.path }
        }
        return Bundle.main.path(forResource: name, ofType: "jpg")
            ?? Bundle.main.path(forResource: name, ofType: "png")
    }

    /// SVG図のファイルパスを「キャッシュ(同梱タグ一致時)優先・無ければ内蔵」で解決する。
    /// jpg/png と同じ figure名(拡張子なし)で引く。imagePathとは別にする(同名のjpgを拾わないため)。
    static func svgPath(name: String) -> String? {
        if let f = cachedFile("content/images/\(name).svg") { return f.path }
        return Bundle.main.path(forResource: name, ofType: "svg")
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
            for (k, v) in cached {
                let file = cacheDir.appendingPathComponent(localName(k))
                if FileManager.default.fileExists(atPath: file.path) { base[k] = v }
            }
        }
        return base
    }

    private static func isOtaTarget(_ key: String) -> Bool { key.hasPrefix("content/") }

    struct SyncResult {
        let updated: Int
        let failed: Int
        let message: String?
    }

    /// 差分取得の進捗と失敗を返す。画像を先に取得し、不足があれば教材の切替を保留する。
    @discardableResult
    static func sync(onProgress: (@MainActor (Int, Int) -> Void)? = nil) async -> SyncResult {
        do {
            try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        } catch {
            return SyncResult(updated: 0, failed: 1, message: "更新データの保存先を作成できませんでした。端末の空き容量を確認してください。")
        }

        // 目次(_manifest.json)は毎回「最新」を掴む(?t=時刻 + no-store)。
        // 古いCDN/端末キャッシュを掴むと「変化なし」と誤判定して更新されないため。
        let ts = Int(Date().timeIntervalSince1970 * 1000)
        guard let murl = URL(string: baseURL + "_manifest.json?t=\(ts)") else {
            return SyncResult(updated: 0, failed: 1, message: "更新先を確認できませんでした。")
        }
        var mreq = URLRequest(url: murl, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
        mreq.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        guard let (mdata, mresp) = try? await URLSession.shared.data(for: mreq),
              (mresp as? HTTPURLResponse)?.statusCode == 200,
              let remote = try? JSONDecoder().decode(Manifest.self, from: mdata) else {
            return SyncResult(updated: 0, failed: 1, message: "更新を確認できませんでした。通信を確認して、もう一度お試しください。")
        }

        // 新しいアプリの教材を、まだ更新されていない棚の古い教材へ戻さない。
        // 配信日時のない従来形式では、これまで通りshaによる同期を行う。
        let dateFormatter = ISO8601DateFormatter()
        if let bundledDateString = bundledManifest()?.generatedAt,
           let remoteDateString = remote.generatedAt,
           let bundledDate = dateFormatter.date(from: bundledDateString),
           let remoteDate = dateFormatter.date(from: remoteDateString),
           remoteDate < bundledDate {
            return SyncResult(updated: 0, failed: 0, message: nil)
        }

        var cached = storedBundleTag() == bundleTag() ? readShas() : [:]
        let have = effectiveShas(cached)
        let pending = remote.files.filter { isOtaTarget($0.key) && have[$0.key] != $0.value.sha256 }
            .sorted { $0.key < $1.key } // content/images/ → content/textbook.json
        var updated = 0
        var failed = 0
        if let onProgress { await onProgress(0, pending.count) }
        for (index, item) in pending.enumerated() {
            let (key, entry) = item
            if key == "content/textbook.json", failed > 0 {
                failed += 1
                if let onProgress { await onProgress(index + 1, pending.count) }
                continue
            }
            // 実ファイルも指紋(sha)を ?v= に付けて古いキャッシュを避ける。
            guard let furl = URL(string: baseURL + key + "?v=" + entry.sha256) else {
                failed += 1
                if let onProgress { await onProgress(index + 1, pending.count) }
                continue
            }
            var freq = URLRequest(url: furl, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            freq.setValue("no-store", forHTTPHeaderField: "Cache-Control")
            if let (fdata, fresp) = try? await URLSession.shared.data(for: freq),
               (fresp as? HTTPURLResponse)?.statusCode == 200,
               entry.size.map({ $0 == fdata.count }) ?? true,
               SHA256.hash(data: fdata).map({ String(format: "%02x", $0) }).joined() == entry.sha256 {
                let dest = cacheDir.appendingPathComponent(localName(key))
                if (try? fdata.write(to: dest, options: .atomic)) != nil {
                    cached[key] = entry.sha256
                    updated += 1
                } else { failed += 1 }
            } else { failed += 1 }
            if let onProgress { await onProgress(index + 1, pending.count) }
        }
        do {
            let data = try JSONEncoder().encode(cached)
            try data.write(to: shaPath, options: .atomic)
            try bundleTag().write(to: bundleTagPath, atomically: true, encoding: .utf8)
        } catch {
            return SyncResult(updated: updated, failed: failed + 1,
                              message: "更新データを保存できませんでした。端末の空き容量を確認して、もう一度更新してください。")
        }
        return SyncResult(updated: updated, failed: failed,
                          message: failed == 0 ? nil : "一部のデータを取得できませんでした。もう一度更新してください。")
    }
}
