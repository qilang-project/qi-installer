#!/usr/bin/env bash
# 更新 brew formula + winget manifest 的版本号与 sha256。
# 每次发新版后跑一次：从 GitHub release 拉三平台包、算 sha256、回填清单。
#
#   用法： qi-installer/scripts/更新安装清单.sh <tag>
#   例：   qi-installer/scripts/更新安装清单.sh 2026.07.10-2
#
# 依赖：gh（GitHub CLI，已登录）、shasum。
set -euo pipefail

TAG="${1:?用法: 更新安装清单.sh <release-tag>}"
REPO="qilang-project/qi"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"      # qi-installer/
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "→ 下载 $TAG 三平台包…"
cd "$TMP"
gh release download "$TAG" --repo "$REPO" \
  --pattern "*macos-arm64.tar.gz" --pattern "*linux-x64.tar.gz" --pattern "*windows-x64.zip"

MAC_SHA=$(shasum -a 256 "qi-$TAG-macos-arm64.tar.gz" | awk '{print $1}')
LINUX_SHA=$(shasum -a 256 "qi-$TAG-linux-x64.tar.gz" | awk '{print $1}')
WIN_SHA=$(shasum -a 256 "qi-$TAG-windows-x64.zip" | awk '{print $1}' | tr 'a-f' 'A-F')  # winget 用大写

echo "  macOS  : $MAC_SHA"
echo "  Linux  : $LINUX_SHA"
echo "  Windows: $WIN_SHA"

# ── 1. Homebrew formula（就地改版本、URL、sha256）──
BREW="$ROOT/brew/qi.rb"
python3 - "$BREW" "$TAG" "$MAC_SHA" "$LINUX_SHA" <<'PY'
import re, sys
p, tag, mac, linux = sys.argv[1:5]
s = open(p, encoding="utf-8").read()
s = re.sub(r'version "[^"]+"', f'version "{tag}"', s, count=1)
# URL 里的旧 tag 全换成新 tag。注意版本号本身含连字符（2026.07.10-2），
# 不能用 [^-]+；用非贪婪 [^"]+? 匹配到平台后缀前。
s = re.sub(r'download/[^/]+/qi-[^"]+?-macos-arm64\.tar\.gz',
           f'download/{tag}/qi-{tag}-macos-arm64.tar.gz', s)
s = re.sub(r'download/[^/]+/qi-[^"]+?-linux-x64\.tar\.gz',
           f'download/{tag}/qi-{tag}-linux-x64.tar.gz', s)
# 按平台替换 sha256：macOS 块紧跟 macos-arm64 url，linux 块紧跟 linux-x64 url
s = re.sub(r'(macos-arm64\.tar\.gz"\n\s*sha256 ")[0-9a-f]+', r'\g<1>'+mac, s)
s = re.sub(r'(linux-x64\.tar\.gz"\n\s*sha256 ")[0-9a-f]+', r'\g<1>'+linux, s)
open(p, "w", encoding="utf-8").write(s)
print("  ✓ 更新", p)
PY

# ── 2. winget manifest（目录名含版本，需搬到新版本目录 + 改内容）──
WOLD=$(ls -d "$ROOT"/winget/manifests/q/qilang/qi/*/ | tail -1)
WNEW="$ROOT/winget/manifests/q/qilang/qi/$TAG"
if [ "$(basename "$WOLD")" != "$TAG" ]; then
  mkdir -p "$WNEW"; cp "$WOLD"*.yaml "$WNEW"/
fi
python3 - "$WNEW" "$TAG" "$WIN_SHA" <<'PY'
import re, sys, glob, os
d, tag, win = sys.argv[1:4]
for f in glob.glob(os.path.join(d, "*.yaml")):
    s = open(f, encoding="utf-8").read()
    s = re.sub(r'PackageVersion: .+', f'PackageVersion: {tag}', s)
    s = re.sub(r'download/[^/]+/qi-[^"]+?-windows-x64\.zip',
               f'download/{tag}/qi-{tag}-windows-x64.zip', s)
    s = re.sub(r'InstallerSha256: [0-9A-Fa-f]+', f'InstallerSha256: {win}', s)
    open(f, "w", encoding="utf-8").write(s)
print("  ✓ 更新", d)
PY

echo "✅ 完成。检查 diff 后提交 qi-installer/。"
