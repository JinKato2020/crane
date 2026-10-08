# tools/content_manifest.py — クレーン コンテンツOTA用 manifest 生成
#
# 役割: アプリに載る「問題(exams.json)/教材・用語(textbook.json)」の sha256 と size を
#       1つの _manifest.json(指紋台帳)に書き出す。
#   ・アプリ本体にはこの _manifest.json を「同梱baseline」として Resources に入れる。
#   ・同じ _manifest.json を配信先 content.safa-lang.com/crane/ にも置く。
#   ・端末は「配信manifestのsha」と「手持ちsha」を比べ、変わったファイルだけDLする。
#
# 配信キー体系(端末/配信で共通): content/exams.json, content/textbook.json
# 配信URL = https://content.safa-lang.com/crane/<key>
#
# 使い方: python tools/content_manifest.py   （crane-app リポジトリ直下で実行）

import hashlib
import json
import os
import sys
from datetime import datetime, timezone

# ---- CONFIG -------------------------------------------------------------
APP_ID = "crane"
RES_DIR = os.path.join("CraneExam", "Resources")      # Resources の場所
CONTENT_FILES = ["exams.json", "textbook.json"]       # OTA対象(問題・教材/用語)
MANIFEST_OUT = os.path.join(RES_DIR, "_manifest.json")  # 同梱baseline兼配信ファイル
# ------------------------------------------------------------------------


def sha256_of(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    root = os.getcwd()
    files = {}
    for name in CONTENT_FILES:
        full = os.path.join(root, RES_DIR, name)
        if not os.path.isfile(full):
            print(f"[warn] 無し: {full}", file=sys.stderr)
            continue
        key = f"content/{name}"
        files[key] = {"sha256": sha256_of(full), "size": os.path.getsize(full)}

    manifest = {
        "appId": APP_ID,
        "schema": 1,
        "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "files": dict(sorted(files.items())),  # キー順を安定化
    }
    out_path = os.path.join(root, MANIFEST_OUT)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
        f.write("\n")

    total_mb = sum(v["size"] for v in files.values()) / 1024 / 1024
    print(f"appId={APP_ID}  files={len(files)}  total={total_mb:.2f}MB")
    print(f"out: {out_path}  ({os.path.getsize(out_path)/1024:.0f}KB)")


if __name__ == "__main__":
    main()
