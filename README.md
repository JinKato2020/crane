# クレーン試験対策アプリ (CraneExam)

クレーン・デリック運転士試験の学習用 iOS アプリ（SwiftUI）。

## v1 の機能
- 5タブ構成：**ホーム / 学科 / 成績 / マイノート / 設定**
- **学科**にオリジナル模擬試験 **全8回（各40問・計320問）** を収録。解答・採点・解説表示。
- 結果は端末内に保存し、**成績**で得点・分野別正答率・弱点分析を表示。
- 間違えた問題・ブックマークを**マイノート**に自動集約。
- ダークテーマ（ゴールドアクセント）。ホームにヒーロー画像。

## 技術構成
- SwiftUI / iOS 16+
- Xcode プロジェクトは **XcodeGen**（`project.yml`）から生成（`.xcodeproj` はコミットしない）
- **GitHub Actions（macOS ランナー）** で自動ビルド → **TestFlight 内部テスト**へアップロード

## 問題データ
- `CraneExam/Resources/exams.json`（320問）は**すべてオリジナルの作問**です。
- 市販教科書の全文テキスト等の著作物はこのリポジトリに**含めていません**。

---

## セットアップ（CIで TestFlight へ出すまで）

### 前提
1. Apple Developer Program 加入済み。
2. App Store Connect に本アプリの枠を作成済み（**Bundle ID を `com.safa.crane` に合わせる**。別IDにする場合は `project.yml` と ASC を一致させる）。
3. App Store Connect API キー（**App Manager** 以上）を発行し、`.p8` ファイルを取得。

### GitHub Secrets（リポジトリ Settings → Secrets and variables → Actions）
| Secret 名 | 内容 |
|-----------|------|
| `DEVELOPMENT_TEAM` | Apple Developer の Team ID（10桁。例 `A1B2C3D4E5`） |
| `ASC_KEY_ID` | App Store Connect API キーの Key ID |
| `ASC_ISSUER_ID` | API キーの Issuer ID（UUID） |
| `ASC_KEY_P8_BASE64` | `.p8` ファイルを base64 化した文字列 |

`.p8` の base64 化：
```bash
# macOS / Linux
base64 -i AuthKey_XXXXXX.p8 | tr -d '\n'
# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("AuthKey_XXXXXX.p8"))
```
出力文字列を `ASC_KEY_P8_BASE64` に貼り付け。

### ビルドの実行
- `main` ブランチに push すると自動実行。
- もしくは GitHub の **Actions** タブ → *iOS Build & TestFlight* → **Run workflow**（手動実行）。
- 成功すると TestFlight に出ます（内部テスターは App Store Connect の TestFlight で追加）。処理反映まで数分かかります。

> ⚠️ ビルド番号は実行時刻から自動採番します。TestFlight への1日のアップロード回数には Apple 非公開の上限があるため、**修正はまとめて**上げてください。

---

## ローカル開発（Mac が必要）
```bash
brew install xcodegen
xcodegen generate      # CraneExam.xcodeproj を生成
open CraneExam.xcodeproj
```

## ディレクトリ
```
crane-app/
├─ project.yml                  # XcodeGen 定義
├─ .github/workflows/ios.yml    # CI（ビルド→TestFlight）
└─ CraneExam/
   ├─ CraneExamApp.swift        # エントリ
   ├─ Theme.swift / Router.swift / Models.swift / Store.swift / Components.swift
   ├─ Views/                    # Home / Study / Quiz / Result / Score / Note / Settings
   ├─ Resources/exams.json      # 模試8回=320問（オリジナル）
   └─ Assets.xcassets/          # AppIcon / AccentColor / Hero
```
