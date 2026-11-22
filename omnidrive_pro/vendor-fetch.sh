#!/bin/sh
# Tải các thư viện front-end (self-hosted) lúc build image.
# Mỗi gói được ghim phiên bản + SHA-256 của tarball npm: nếu file tải về bị thay đổi, build sẽ dừng.
# Cập nhật: đổi phiên bản, rồi lấy SHA-256 mới bằng
#   curl -sL https://registry.npmjs.org/<pkg>/-/<name>-<ver>.tgz | sha256sum
set -eu

DEST="${1:-/usr/share/nginx/fancyindex/vendor}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
REG="https://registry.npmjs.org"

fetch() { # <id> <url> <sha256>
    curl -fsSL --retry 5 --retry-delay 3 -o "$TMP/$1.tgz" "$2"
    echo "$3  $TMP/$1.tgz" | sha256sum -c -
    mkdir -p "$TMP/$1"
    tar -xzf "$TMP/$1.tgz" -C "$TMP/$1"
}

fetch ace    "$REG/ace-builds/-/ace-builds-1.45.2.tgz"   5260354a14533fa8e94572597b1ff53025b1bb0a9b2e25d50ecf2a01e57aa9e0
fetch marked "$REG/marked/-/marked-18.2.1.tgz"           d66c5213fc203466186060105b01f51896764ba64b3797d2620d02e28e34b8ca
fetch purify "$REG/dompurify/-/dompurify-3.5.0.tgz"      faa5f2bfe2814384b83d6edb4ed66812fbfdb2a654b4d59edd4b12304058ec20
fetch yaml   "$REG/js-yaml/-/js-yaml-4.3.2.tgz"          c7b241d2224cf9253ff53854aa4cee87da91bd889c4d0fa3a3ffd1041ecee5b1
fetch jszip  "$REG/jszip/-/jszip-3.10.2.tgz"             4ee15dcb3f5433b736a41d091bcad37facee4a4aa96f9e21194789da886ac226
fetch pdfjs  "$REG/pdfjs-dist/-/pdfjs-dist-6.5.438.tgz"  7461aefcd27c4ef0dd76f9ca5760f09466eb6b3f934432670c12132e7b3d6faa
fetch xterm  "$REG/@xterm/xterm/-/xterm-6.0.0.tgz"       908e66e04af6c8dc6b00dd3b54de088e2e81e5ed866284fd6c2fb3c2d1c7a3f6

mkdir -p "$DEST/ace" "$DEST/pdfjs/wasm"

# Ace editor: lõi, ô tìm kiếm, theme và các mode (nạp động qua basePath)
ACE="$TMP/ace/package/src-min-noconflict"
cp "$ACE/ace.js" "$ACE/ext-searchbox.js" "$ACE/theme-one_dark.js" "$DEST/ace/"
cp "$ACE"/mode-*.js "$DEST/ace/"

cp "$TMP/marked/package/lib/marked.umd.js"        "$DEST/marked.min.js"
cp "$TMP/purify/package/dist/purify.min.js"       "$DEST/purify.min.js"
cp "$TMP/yaml/package/dist/js-yaml.min.js"        "$DEST/js-yaml.min.js"
cp "$TMP/jszip/package/dist/jszip.min.js"         "$DEST/jszip.min.js"
cp "$TMP/xterm/package/lib/xterm.js"              "$DEST/xterm.min.js"
cp "$TMP/xterm/package/css/xterm.css"             "$DEST/xterm.min.css"

# pdf.js (ES module, nạp bằng import() khi mở PDF). Đổi đuôi .mjs -> .js để Nginx trả đúng MIME JavaScript.
PDF="$TMP/pdfjs/package"
cp "$PDF/build/pdf.min.mjs"        "$DEST/pdfjs/pdf.module.js"
cp "$PDF/build/pdf.worker.min.mjs" "$DEST/pdfjs/pdf.worker.module.js"
cp -r "$PDF/cmaps" "$PDF/standard_fonts" "$DEST/pdfjs/"
cp "$PDF"/wasm/openjpeg.wasm "$PDF"/wasm/openjpeg_nowasm_fallback.js \
   "$PDF"/wasm/jbig2.wasm "$PDF"/wasm/jbig2_nowasm_fallback.js \
   "$PDF"/wasm/qcms_bg.wasm "$DEST/pdfjs/wasm/"

# Kiểm tra nhanh: đủ file bắt buộc
for f in ace/ace.js ace/ext-searchbox.js ace/theme-one_dark.js ace/mode-yaml.js marked.min.js purify.min.js \
         js-yaml.min.js jszip.min.js xterm.min.js xterm.min.css pdfjs/pdf.module.js pdfjs/pdf.worker.module.js; do
    [ -s "$DEST/$f" ] || { echo "vendor-fetch: missing $f" >&2; exit 1; }
done
chmod -R a+rX "$DEST"
echo "vendor-fetch: front-end libraries installed in $DEST"
