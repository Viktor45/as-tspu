#!/bin/sh

# Downloads ipverse AS aggregation files for each AS number in as-numbers.txt.
# Produces ipverse/ipv4.txt, ipverse/ipv6.txt, and ipverse/merged.txt.

set -eu

BASE_URL="https://raw.githubusercontent.com/ipverse/as-ip-blocks/refs/heads/master/as"
OUTPUT_DIR="ipverse"
IPV4_DIR="$OUTPUT_DIR/ipv4"
IPV6_DIR="$OUTPUT_DIR/ipv6"
INPUT_FILE="as-numbers.txt"

mkdir -p "$IPV4_DIR" "$IPV6_DIR"

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: $INPUT_FILE not found." >&2
  exit 1
fi

download_file() {
  url="$1"
  dest="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$dest" "$url"
  else
    echo "Error: curl or wget is required." >&2
    exit 1
  fi
}

while IFS= read -r line || [ -n "$line" ]; do
  # strip comments and whitespace
  asnumber="$(printf '%s' "$line" | cut -d '#' -f 1 | tr -d '[:space:]')"
  if [ -z "$asnumber" ]; then
    continue
  fi

  ipv4_dest="$IPV4_DIR/${asnumber}.txt"
  ipv6_dest="$IPV6_DIR/${asnumber}.txt"

  echo "Downloading AS$asnumber..."
  download_file "$BASE_URL/$asnumber/ipv4-aggregated.txt" "$ipv4_dest" || {
    echo "Warning: failed to download IPv4 for AS$asnumber" >&2
    rm -f "$ipv4_dest"
  }

  download_file "$BASE_URL/$asnumber/ipv6-aggregated.txt" "$ipv6_dest" || {
    echo "Warning: failed to download IPv6 for AS$asnumber" >&2
    rm -f "$ipv6_dest"
  }

done < "$INPUT_FILE"

printf '%s\n' "$OUTPUT_DIR/ipv4.txt" "$OUTPUT_DIR/ipv6.txt" "$OUTPUT_DIR/merged.txt" >/dev/null

# Merge downloaded files
cat "$IPV4_DIR"/*.txt 2>/dev/null > "$OUTPUT_DIR/ipv4.txt" || true
cat "$IPV6_DIR"/*.txt 2>/dev/null > "$OUTPUT_DIR/ipv6.txt" || true
cat "$OUTPUT_DIR/ipv4.txt" "$OUTPUT_DIR/ipv6.txt" > "$OUTPUT_DIR/merged.txt"

echo "Done."
echo "Created: $OUTPUT_DIR/ipv4.txt, $OUTPUT_DIR/ipv6.txt, $OUTPUT_DIR/merged.txt"
