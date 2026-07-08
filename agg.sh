#!/bin/sh

# Downloads the latest cidrmgr release from GitHub, extracts the binary,
# and aggregates ipverse IPv4/IPv6 files for GitHub Actions.

set -eu

REPO="Viktor45/cidrmgr"
API_URL="https://api.github.com/repos/$REPO/releases/latest"
BINARY_NAME="cidrmgr"
BINARY_TARBALL="cidrmgr.tar.gz"
BINARY_PATH="./$BINARY_NAME"
INPUT_IPV4="ipverse/ipv4.txt"
INPUT_IPV6="ipverse/ipv6.txt"
OUTPUT_IPV4="ipverse/ipv4-agg.txt"
OUTPUT_IPV6="ipverse/ipv6-agg.txt"
MERGED_OUTPUT="ipverse/merged-agg.txt"

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

http_get() {
  url="$1"
  dest="$2"

  if command -v wget >/dev/null 2>&1; then
    wget --retry-on-http-error=429 --waitretry=3 --tries=3 -q -O "$dest" "$url"
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  else
    fail "curl or wget is required to download the cidrmgr release"
  fi
}

detect_platform() {
  case "$(uname -s)" in
    Linux) os=linux ;;
    Darwin) os=darwin ;;
    *) fail "Unsupported OS: $(uname -s)" ;;
  esac

  case "$(uname -m)" in
    x86_64|amd64) arch=x86_64 ;;
    aarch64|arm64) arch=arm64 ;;
    armv7*|armv6*) arch=arm ;;
    *) fail "Unsupported architecture: $(uname -m)" ;;
  esac
}

if [ ! -f "$INPUT_IPV4" ]; then
  fail "$INPUT_IPV4 not found"
fi

if [ ! -f "$INPUT_IPV6" ]; then
  fail "$INPUT_IPV6 not found"
fi

detect_platform

printf 'Detecting release asset for %s-%s...\n' "$os" "$arch"
http_get "$API_URL" /tmp/cidrmgr_release.json
if [ ! -s /tmp/cidrmgr_release.json ]; then
  fail "Failed to fetch GitHub release metadata"
fi

asset_url=$(grep '"browser_download_url"' /tmp/cidrmgr_release.json | sed -E 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' | grep -E "${BINARY_NAME}_[^/]+_${os}_${arch}\.tar\.gz" | head -n 1 || true)
rm -f /tmp/cidrmgr_release.json

if [ -z "$asset_url" ]; then
  fail "Could not find a matching cidrmgr asset for ${os}/${arch} in latest release"
fi

printf 'Downloading cidrmgr from %s\n' "$asset_url"
http_get "$asset_url" "$BINARY_TARBALL"

tar -xzf "$BINARY_TARBALL" "$BINARY_NAME"
rm -f "$BINARY_TARBALL"

if [ ! -f "$BINARY_PATH" ]; then
  fail "Failed to extract $BINARY_NAME from release archive"
fi

chmod +x "$BINARY_PATH"

printf 'Running cidrmgr merge on %s -> %s\n' "$INPUT_IPV4" "$OUTPUT_IPV4"
./$BINARY_NAME merge -i "$INPUT_IPV4" -o "$OUTPUT_IPV4"

printf 'Running cidrmgr merge on %s -> %s\n' "$INPUT_IPV6" "$OUTPUT_IPV6"
./$BINARY_NAME merge -i "$INPUT_IPV6" -o "$OUTPUT_IPV6"

printf 'Merging aggregated files into %s\n' "$MERGED_OUTPUT"
cat "$OUTPUT_IPV4" "$OUTPUT_IPV6" > "$MERGED_OUTPUT"

printf 'Done. Generated %s, %s, and %s\n' "$OUTPUT_IPV4" "$OUTPUT_IPV6" "$MERGED_OUTPUT"
