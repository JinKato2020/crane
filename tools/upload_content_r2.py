# tools/upload_content_r2.py — クレーン コンテンツOTA: R2(棚)へアップロード
#
# 役割: Resources の exams.json / textbook.json / images/* と _manifest.json を
#       Cloudflare R2 の棚 (content.safa-lang.com/crane/) へ上げる。
#       これ1本で「内容を更新 → 実行 → 全端末が次回起動で反映」の無ビルド運用になる。
#
# 仕組み:
#   1. content_manifest.py を呼んで _manifest.json を最新化(sha/size)。
#   2. 棚の現行 _manifest.json を取得し、sha が変わった(or 新規)ファイルだけアップロード。
#   3. 最後に _manifest.json を上げる(=実ファイルが揃ってから目次を更新する安全順序)。
#
# 必要な環境変数(ハードコード禁止。シェルや tools/.r2.env に置く):
#   R2_ACCOUNT_ID         … Cloudflare アカウントID(32桁hex)
#   R2_ACCESS_KEY_ID      … R2 APIトークンの Access Key ID
#   R2_SECRET_ACCESS_KEY  … 同 Secret Access Key
#   R2_BUCKET             … 配信バケット名
#   R2_PREFIX             … 省略可。既定 "crane/"(= content.safa-lang.com/crane/ に対応)
#
# 事前準備(初回のみ): pip install boto3
#   認証情報は tools/.r2.env(KEY=VALUE 形式, gitignore 済)にも置ける。
#
# 使い方:
#   cd crane-app
#   python tools/upload_content_r2.py            # 差分アップロード
#   python tools/upload_content_r2.py --all      # 全ファイル強制アップロード
#   python tools/upload_content_r2.py --dry-run  # 何を上げるか表示のみ

import hashlib
import json
import os
import subprocess
import sys

RES_DIR = os.path.join("CraneExam", "Resources")
MANIFEST = os.path.join(RES_DIR, "_manifest.json")
HERE = os.path.dirname(os.path.abspath(__file__))


def sha256_of(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def load_env_file():
    """tools/.r2.env があれば環境変数へ読み込む(既存のenvは上書きしない)。"""
    p = os.path.join(HERE, ".r2.env")
    if not os.path.isfile(p):
        return
    for line in open(p, encoding="utf-8"):
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))


def content_type(key):
    if key.endswith(".json"):
        return "application/json; charset=utf-8"
    if key.endswith(".png"):
        return "image/png"
    if key.endswith(".jpg") or key.endswith(".jpeg"):
        return "image/jpeg"
    return "application/octet-stream"


def key_to_localpath(key):
    # content/exams.json -> Resources/exams.json
    # content/images/x.png -> Resources/images/x.png
    rel = key[len("content/"):] if key.startswith("content/") else key
    return os.path.join(RES_DIR, rel)


def main():
    args = sys.argv[1:]
    dry = "--dry-run" in args
    force_all = "--all" in args
    load_env_file()

    root = os.getcwd()
    if not os.path.isfile(os.path.join(root, MANIFEST.replace("/", os.sep))) and \
       not os.path.isdir(os.path.join(root, RES_DIR)):
        sys.exit("crane-app 直下で実行してください(CraneExam/Resources が見つからない)。")

    # 1) manifest を最新化
    print("[1/3] _manifest.json を再生成…")
    subprocess.run([sys.executable, os.path.join("tools", "content_manifest.py")], check=True)
    manifest = json.load(open(os.path.join(root, MANIFEST), encoding="utf-8"))
    files = manifest["files"]  # {key: {sha256,size}}

    # 2) R2 クライアント
    acct = os.environ.get("R2_ACCOUNT_ID")
    akid = os.environ.get("R2_ACCESS_KEY_ID")
    secret = os.environ.get("R2_SECRET_ACCESS_KEY")
    bucket = os.environ.get("R2_BUCKET")
    prefix = os.environ.get("R2_PREFIX", "crane/")
    missing = [n for n, v in [("R2_ACCOUNT_ID", acct), ("R2_ACCESS_KEY_ID", akid),
                              ("R2_SECRET_ACCESS_KEY", secret), ("R2_BUCKET", bucket)] if not v]
    if missing and not dry:
        sys.exit("環境変数が未設定: " + ", ".join(missing) + "\n  tools/.r2.env か shell で設定してください。")

    client = None
    remote_manifest = {}
    if not dry:
        try:
            import boto3
            from botocore.config import Config
        except ImportError:
            sys.exit("boto3 が必要です。先に:  pip install boto3")
        client = boto3.client(
            "s3",
            endpoint_url=f"https://{acct}.r2.cloudflarestorage.com",
            aws_access_key_id=akid, aws_secret_access_key=secret,
            config=Config(signature_version="s3v4", region_name="auto"),
        )
        # 棚の現行 manifest を取得(差分判定用。無ければ全て新規扱い)
        try:
            obj = client.get_object(Bucket=bucket, Key=prefix + "_manifest.json")
            remote_manifest = json.loads(obj["Body"].read()).get("files", {})
        except Exception:
            remote_manifest = {}

    # 3) 差分抽出(sha変化 or 新規)。--all なら全件。
    to_upload = []
    for key, ent in sorted(files.items()):
        changed = force_all or remote_manifest.get(key, {}).get("sha256") != ent["sha256"]
        if changed:
            to_upload.append(key)

    total_mb = sum(files[k]["size"] for k in to_upload) / 1024 / 1024
    print(f"[2/3] 対象 {len(to_upload)}/{len(files)} ファイル({total_mb:.2f}MB) prefix='{prefix}'"
          + ("  [DRY-RUN]" if dry else ""))
    for k in to_upload[:40]:
        print("   +", k)
    if len(to_upload) > 40:
        print(f"   … 他 {len(to_upload)-40} 件")
    if dry:
        print("[dry-run] アップロードは行いません。")
        return
    if not to_upload:
        print("変更なし。アップロード不要です(manifestも最新)。")
        return

    # 実ファイルを先に、_manifest.json は最後に。
    done = 0
    for key in to_upload:
        lp = os.path.join(root, key_to_localpath(key))
        if not os.path.isfile(lp):
            print("   !! ローカルに無い(スキップ):", lp); continue
        client.upload_file(lp, bucket, prefix + key,
                           ExtraArgs={"ContentType": content_type(key), "CacheControl": "no-cache"})
        done += 1
    # 目次を最後に更新
    client.upload_file(os.path.join(root, MANIFEST), bucket, prefix + "_manifest.json",
                       ExtraArgs={"ContentType": "application/json; charset=utf-8",
                                  "CacheControl": "no-cache"})
    print(f"[3/3] 完了: 実ファイル {done} 件 + _manifest.json を {bucket}/{prefix} へアップロード。")
    print("端末は次回起動で差分DL→反映します。")


if __name__ == "__main__":
    main()
