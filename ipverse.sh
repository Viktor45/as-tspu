#!/bin/sh
# Downloads ipverse AS aggregation files for each AS number in as-numbers.txt.
# Produces ipverse/ipv4.txt, ipverse/ipv6.txt, ipverse/merged.txt,
# and corresponding .lst files (asnumber,line format, no comments).
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

# Converts downloaded file to .lst format: asnumber,line
# Skips comment lines (starting with #) and empty/whitespace-only lines.
make_lst() {
    src="$1"
    dest="$2"
    asnum="$3"
    if [ -f "$src" ]; then
        awk -v as="$asnum" '!/^[[:space:]]*#/ && NF {print as","$0}' "$src" > "$dest"
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
    ipv4_lst="$IPV4_DIR/${asnumber}.lst"
    ipv6_lst="$IPV6_DIR/${asnumber}.lst"
    echo "Downloading AS$asnumber..."
    download_file "$BASE_URL/$asnumber/ipv4-aggregated.txt" "$ipv4_dest" || {
        echo "Warning: failed to download IPv4 for AS$asnumber" >&2
        rm -f "$ipv4_dest"
    }
    download_file "$BASE_URL/$asnumber/ipv6-aggregated.txt" "$ipv6_dest" || {
        echo "Warning: failed to download IPv6 for AS$asnumber" >&2
        rm -f "$ipv6_dest"
    }
    # Generate .lst files from successfully downloaded sources
    make_lst "$ipv4_dest" "$ipv4_lst" "$asnumber"
    make_lst "$ipv6_dest" "$ipv6_lst" "$asnumber"
done < "$INPUT_FILE"

# Merge downloaded .txt files
cat "$IPV4_DIR"/*.txt 2>/dev/null > "$OUTPUT_DIR/ipv4.txt" || true
cat "$IPV6_DIR"/*.txt 2>/dev/null > "$OUTPUT_DIR/ipv6.txt" || true
cat "$OUTPUT_DIR/ipv4.txt" "$OUTPUT_DIR/ipv6.txt" > "$OUTPUT_DIR/merged.txt"

# Merge .lst files
cat "$IPV4_DIR"/*.lst 2>/dev/null > "$OUTPUT_DIR/ipv4.lst" || true
cat "$IPV6_DIR"/*.lst 2>/dev/null > "$OUTPUT_DIR/ipv6.lst" || true
cat "$OUTPUT_DIR/ipv4.lst" "$OUTPUT_DIR/ipv6.lst" > "$OUTPUT_DIR/merged.lst"

echo "Done."
echo "Created: $OUTPUT_DIR/ipv4.txt, $OUTPUT_DIR/ipv6.txt, $OUTPUT_DIR/merged.txt"
echo "Created: $OUTPUT_DIR/ipv4.lst, $OUTPUT_DIR/ipv6.lst, $OUTPUT_DIR/merged.lst"