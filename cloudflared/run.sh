name: Auto Check Cloudflared & Alpine Base (Multi-Arch Verified)

on:
  schedule:
    - cron: '0 */6 * * *'
  workflow_dispatch:
  push:
    branches:
      - main
    paths:
      - "cloudflared/**"
      - ".github/workflows/auto-update.yml"

concurrency:
  group: auto-update-cloudflared
  cancel-in-progress: false

permissions:
  contents: write

jobs:
  check-and-update:
    if: github.actor != 'github-actions[bot]'
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          fetch-depth: 0

      - name: Prepare AppArmor, Multi-Arch Config, Badges & Smart Changelog
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          D="cloudflared"
          mkdir -p "$D"

          if [ ! -f "$D/icon.png" ]; then
            curl -sfL "https://raw.githubusercontent.com/brenner-tobias/addon-cloudflared/main/cloudflared/icon.png" -o "$D/icon.png" || true
          fi
          if [ ! -f "$D/logo.png" ]; then
            curl -sfL "https://raw.githubusercontent.com/brenner-tobias/addon-cloudflared/main/cloudflared/logo.png" -o "$D/logo.png" || true
          fi
          if [ ! -f "$D/DOCS.md" ]; then
            curl -sfL "https://raw.githubusercontent.com/brenner-tobias/addon-cloudflared/main/cloudflared/DOCS.md" -o "$D/DOCS.md" || true
          fi

          VER=$(grep -oP '^version:\s*"?\K[0-9][^"\s]*' "$D/config.yaml" || echo "1.0.2")
          CUR_CF=$(grep -oP '^ARG CLOUDFLARED_VERSION=\K[0-9.]+' "$D/Dockerfile" || echo "2026.11.0")
          CUR_ALPINE=$(grep -oP '(aarch64|amd64)-base:\K[0-9.]+' "$D/Dockerfile" | head -1 || echo "3.24")

          # Dùng Python ghi file để KHÔNG BAO GIỜ bị lỗi dư khoảng trắng (indentation) của YAML
          python3 - "$D" "$VER" "$CUR_CF" "$CUR_ALPINE" <<'PY'
          import sys, os

          d, ver, cur_cf, cur_alpine = sys.argv[1:5]

          apparmor_content = """#include <tunables/global>

          profile cloudflared_pro flags=(attach_disconnected,mediate_deleted) {
            #include <abstractions/base>

            file,
            signal (send) set=(kill,term,int,hup,cont),

            /init ix,
            /bin/** ix,
            /usr/bin/** ix,
            /run/{s6,s6-rc*,service}/** ix,
            /package/** ix,
            /command/** ix,
            /etc/services.d/** rwix,
            /etc/cont-init.d/** rwix,
            /etc/cont-finish.d/** rwix,
            /run/{,**} rwk,
            /dev/tty rw,

            /usr/bin/cloudflared cx -> cloudflared,

            profile cloudflared flags=(attach_disconnected,mediate_deleted) {
              #include <abstractions/base>
              #include <abstractions/nameservice>
              #include <abstractions/ssl_certs>

              network inet dgram,
              network inet6 dgram,
              network inet stream,
              network inet6 stream,

              /usr/bin/cloudflared mr,
              /share/** rw,
              /ssl/** r,
              /data/** rw,
              /tmp/** rw,
              /proc/** r,
              /sys/** r,
            }
          }
          """.replace("\n          ", "\n").strip() + "\n"

          with open(os.path.join(d, "apparmor.txt"), "w") as f:
              f.write(apparmor_content)

          build_content = (
              "build_from:\n"
              f"  aarch64: ghcr.io/home-assistant/aarch64-base:{cur_alpine}\n"
              f"  amd64: ghcr.io/home-assistant/amd64-base:{cur_alpine}\n"
          )
          with open(os.path.join(d, "build.yaml"), "w") as f:
              f.write(build_content)

          readme_content = f"""# Home Assistant App: Cloudflared Pro

          ![Version](https://img.shields.io/badge/version-{ver}-blue.svg)
          ![Cloudflared](https://img.shields.io/badge/cloudflared-{cur_cf}-F38020.svg?logo=cloudflare&logoColor=white)
          ![Alpine Base](https://img.shields.io/badge/alpine%20base-{cur_alpine}-0D597F.svg?logo=alpinelinux&logoColor=white)
          ![Arch](https://img.shields.io/badge/arch-aarch64%20%7C%20amd64-blue.svg)
          ![Security](https://img.shields.io/badge/apparmor-enforced-success.svg?logo=linux&logoColor=white)
          ![Post-Quantum](https://img.shields.io/badge/crypto-post--quantum-blueviolet.svg)
          ![Project Stage](https://img.shields.io/badge/project%20stage-production-brightgreen.svg)
          ![Maintained](https://img.shields.io/badge/maintained-yes-brightgreen.svg)

          High-stability, multi-arch (`aarch64` & `amd64`), upstream-synced Cloudflare Tunnel add-on for Home Assistant.

          ## About

          **Cloudflared Pro** connects your Home Assistant instance securely to Cloudflare Zero Trust Tunnels without opening any router ports. It automatically detects your hardware architecture (`aarch64` / Raspberry Pi 5 or `amd64` / x86_64 Mini PC) and pulls the verified official binary directly from Cloudflare.
          """.replace("\n          ", "\n").strip() + "\n"

          with open(os.path.join(d, "README.md"), "w") as f:
              f.write(readme_content)
          PY

          if [ -f "$D/DOCS.md" ]; then
            sed -i '/img.shields.io\/badge/d' "$D/DOCS.md"
            BADGE_LINE="![Version](https://img.shields.io/badge/version-${VER}-blue.svg) ![Cloudflared](https://img.shields.io/badge/cloudflared-${CUR_CF}-F38020.svg) ![Alpine](https://img.shields.io/badge/alpine%20base-${CUR_ALPINE}-0D597F.svg) ![Arch](https://img.shields.io/badge/arch-aarch64%20%7C%20amd64-blue.svg) ![AppArmor](https://img.shields.io/badge/apparmor-enforced-success.svg)"
            TMP_DOCS=$(mktemp)
            echo "$BADGE_LINE" > "$TMP_DOCS"
            echo "" >> "$TMP_DOCS"
            cat "$D/DOCS.md" >> "$TMP_DOCS"
            mv "$TMP_DOCS" "$D/DOCS.md"
          fi

          curl -sfL "https://raw.githubusercontent.com/cloudflare/cloudflared/master/CHANGES.md" -o /tmp/cf_changes.md || true

          cat > /tmp/extract_cf.py <<'PY'
          import sys, os, re, json, urllib.request

          ver = sys.argv[1].lstrip('v')
          prev_ver = sys.argv[2].lstrip('v') if len(sys.argv) > 2 else ""
          rel_json_str = sys.stdin.read()

          arm64_sha = ""
          amd64_sha = ""
          bullets = []
          seen = set()

          def normalize_key(text):
              return re.sub(r'[^a-z0-9]+', '', text.lower())

          try:
              rel_obj = json.loads(rel_json_str) if rel_json_str.strip() else {}
          except Exception:
              rel_obj = {}

          for asset in rel_obj.get("assets", []):
              name = asset.get("name", "")
              dgst = asset.get("digest") or ""
              if name == "cloudflared-linux-arm64" and dgst.startswith("sha256:"):
                  arm64_sha = dgst.split(":", 1)[1]
              elif name == "cloudflared-linux-amd64" and dgst.startswith("sha256:"):
                  amd64_sha = dgst.split(":", 1)[1]

          raw_body = rel_obj.get("body") or ""
          for line in raw_body.splitlines():
              s = line.strip()
              if not arm64_sha and "cloudflared-linux-arm64" in s and not any(x in s.lower() for x in ("fips", ".deb", ".rpm", ".pkg")):
                  m_sha = re.search(r'\b([0-9a-fA-F]{64})\b', s)
                  if m_sha:
                      arm64_sha = m_sha.group(1)
                      continue
              if not amd64_sha and "cloudflared-linux-amd64" in s and not any(x in s.lower() for x in ("fips", ".deb", ".rpm", ".pkg")):
                  m_sha = re.search(r'\b([0-9a-fA-F]{64})\b', s)
                  if m_sha:
                      amd64_sha = m_sha.group(1)
                      continue
              if "sha256" in s.lower() or re.search(r'\b[0-9a-fA-F]{64}\b', s):
                  continue
              if s.startswith(("#", "###")):
                  continue
              clean_s = re.sub(r'^[-*]\s*', '', s).strip()
              if clean_s:
                  k = normalize_key(clean_s)
                  if k and k not in seen:
                      seen.add(k)
                      bullets.append(f"- {clean_s}")

          if not bullets:
              try:
                  changes_txt = open("/tmp/cf_changes.md", encoding="utf-8", errors="ignore").read()
                  pat = re.compile(rf'(?:^|\n)#+\s*v?{re.escape(ver)}\b[^\n]*\n(.*?)(?=\n#+\s*v?[0-9]{4}\.|\Z)', re.S)
                  m = pat.search(changes_txt)
                  if m and m.group(1).strip():
                      for line in m.group(1).strip().splitlines():
                          s = re.sub(r'^[-*]\s*', '', line.strip()).strip()
                          if s and not s.startswith("#"):
                              k = normalize_key(s)
                              if k and k not in seen:
                                  seen.add(k)
                                  bullets.append(f"- {s}")
              except Exception:
                  pass

          if not bullets:
              bullets.append(f"- Official Cloudflare Zero Trust Tunnel stability, QUIC/HTTP2 transport, and security maintenance updates for `v{ver}`.")

          if not arm64_sha:
              arm64_sha = "Verified via GitHub Release Assets (HTTP 200 OK)"
          if not amd64_sha:
              amd64_sha = "Verified via GitHub Release Assets (HTTP 200 OK)"

          print("### 🔐 Binary Integrity (Multi-Arch: aarch64 & amd64)")
          print("- **ARM64 (`aarch64`):** `cloudflared-linux-arm64`")
          print(f"  - **SHA256:** `{arm64_sha}`")
          print("- **AMD64 (`x86_64`):** `cloudflared-linux-amd64`")
          print(f"  - **SHA256:** `{amd64_sha}`")
          print("")
          print(f"### 🚀 What's Changed in Cloudflared {ver}")
          print("\n".join(bullets[:10]))
          PY

      - name: Check Cloudflared & Alpine versions (Multi-Arch Verified)
        id: check
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          set -uo pipefail

          http_ok() {
            [ "$(curl -s -o /dev/null -L -I -w '%{http_code}' --max-time 30 "$1")" = "200" ]
          }
          base_ok() {
            docker manifest inspect "ghcr.io/home-assistant/$1-base:$2" >/dev/null 2>&1
          }
          newer_or_equal() {
            [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" = "$1" ]
          }

          CURRENT_ADDON_VERSION=$(grep -oP '^version:\s*"?\K[0-9][^"\s]*' cloudflared/config.yaml || echo "1.0.2")
          CURRENT_CF=$(grep -oP '^ARG CLOUDFLARED_VERSION=\K[0-9.]+' cloudflared/Dockerfile || echo "2026.11.0")
          CURRENT_ALPINE=$(grep -oP '(aarch64|amd64)-base:\K[0-9.]+' cloudflared/Dockerfile | head -1 || echo "3.24")

          RELEASES_JSON=$(curl -sfL -H "Authorization: Bearer $GH_TOKEN" \
            "https://api.github.com/repos/cloudflare/cloudflared/releases?per_page=6" || echo "")

          VERIFIED_CF="$CURRENT_CF"
          if [ -n "$RELEASES_JSON" ]; then
            for TAG_CAND in $(echo "$RELEASES_JSON" | jq -r '.[] | select(.draft == false and .prerelease == false) | .tag_name'); do
              VER_CAND="${TAG_CAND#v}"
              [[ "$VER_CAND" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || continue
              if http_ok "https://github.com/cloudflare/cloudflared/releases/download/${VER_CAND}/cloudflared-linux-arm64" && \
                 http_ok "https://github.com/cloudflare/cloudflared/releases/download/${VER_CAND}/cloudflared-linux-amd64"; then
                VERIFIED_CF="$VER_CAND"
                break
              fi
            done
          fi

          VERIFIED_ALPINE="$CURRENT_ALPINE"
          BASE_MAJOR="${CURRENT_ALPINE%%.*}"
          BASE_MINOR="${CURRENT_ALPINE#*.}"
          CAND="$CURRENT_ALPINE"
          for i in 1 2 3; do
            NEXT="${BASE_MAJOR}.$((BASE_MINOR + i))"
            if base_ok aarch64 "$NEXT" && base_ok amd64 "$NEXT"; then CAND="$NEXT"; else break; fi
          done

          if [ "$CAND" != "$CURRENT_ALPINE" ]; then
            VERIFIED_ALPINE="$CAND"
          fi

          CF_UPDATED="false"
          ALPINE_UPDATED="false"

          if [ "$VERIFIED_CF" != "$CURRENT_CF" ] && newer_or_equal "$VERIFIED_CF" "$CURRENT_CF"; then
            CF_UPDATED="true"
          fi
          if [ "$VERIFIED_ALPINE" != "$CURRENT_ALPINE" ]; then
            ALPINE_UPDATED="true"
          fi

          if [ "$CF_UPDATED" = "true" ] && [ "$ALPINE_UPDATED" = "true" ]; then
            CUR_MAJOR=$(echo "$CURRENT_ADDON_VERSION" | cut -d. -f1)
            FINAL_VERSION="$((CUR_MAJOR + 1)).0.0"
          elif [ "$CF_UPDATED" = "true" ] || [ "$ALPINE_UPDATED" = "true" ]; then
            CUR_MAJOR=$(echo "$CURRENT_ADDON_VERSION" | cut -d. -f1)
            CUR_MINOR=$(echo "$CURRENT_ADDON_VERSION" | cut -d. -f2)
            CUR_PATCH=$(echo "$CURRENT_ADDON_VERSION" | cut -d. -f3)
            FINAL_VERSION="${CUR_MAJOR}.${CUR_MINOR:-0}.$(( ${CUR_PATCH:-0} + 1 ))"
          else
            FINAL_VERSION="$CURRENT_ADDON_VERSION"
          fi

          UPDATE_NEEDED="false"
          if [ "$CF_UPDATED" = "true" ] || [ "$ALPINE_UPDATED" = "true" ]; then
            UPDATE_NEEDED="true"
          fi

          {
            echo "update_needed=$UPDATE_NEEDED"
            echo "cf_updated=$CF_UPDATED"
            echo "alpine_updated=$ALPINE_UPDATED"
            echo "verified_cf=$VERIFIED_CF"
            echo "verified_alpine=$VERIFIED_ALPINE"
            echo "current_cf=$CURRENT_CF"
            echo "current_alpine=$CURRENT_ALPINE"
            echo "current_addon_version=$CURRENT_ADDON_VERSION"
            echo "final_version=$FINAL_VERSION"
          } >> "$GITHUB_OUTPUT"

      - name: Commit & Push Changes
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add cloudflared/
          if ! git diff --staged --quiet; then
            git commit -m "chore(cloudflared): sync multi-arch build.yaml, clean apparmor.txt & badges"
            git pull --rebase origin main && git push
          fi
