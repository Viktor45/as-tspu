#!/bin/sh

# fast mikrotik address list rsc script generator
#
# Usage: ./fast-mikrotik.sh <ipv4_file> <ipv6_file> <output_file> <listname> <comment>
#
# example: ./fast-mikrotik.sh ../ipverse/ipv4-agg.txt ../ipverse/ipv6-agg.txt tspu-list bypass TSPU
#
# https://github.com/Viktor45/as-tspu

if [ "$#" -ne 5 ]; then
    echo "Error: Exactly 5 arguments required, but you provided $#." >&2
    echo "Usage: $0 <ipv4_file> <ipv6_file> <output_file> <listname> <comment>" >&2
    exit 1
fi

# 2. Check if each provided path actually exists
for arg in "$1" "$2"; do
    if [ ! -e "$arg" ]; then
        echo "Error: file '$arg' does not exist." >&2
        exit 1
    fi
done

IPV4_FILE=$1
IPV6_FILE=$2
OUTPUT_FILE=$3.rsc
LIST_NAME=$4
COMMENT=$5

# Clear previous output file
> "$OUTPUT_FILE"

## echo ":do {\n" >>"$OUTPUT_FILE"

# Process IPv4 addresses
if [ -f "$IPV4_FILE" ]; then
    echo "/ip firewall address-list" >> "$OUTPUT_FILE"
    sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$IPV4_FILE" | \
    grep -E '^[0-9]' | \
    awk -v list="$LIST_NAME" -v comment="$COMMENT" '{print "add list=" list " comment=" comment " address=" $1}' >> "$OUTPUT_FILE"
fi

# Process IPv6 addresses
if [ -f "$IPV6_FILE" ]; then
    echo "/ipv6 firewall address-list" >> "$OUTPUT_FILE"
    sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$IPV6_FILE" | \
    grep -E '^[0-9a-fA-F:]' | \
    awk -v list="$LIST_NAME" -v comment="$COMMENT" '{print "add list=" list " comment=" comment " address=" $1}' >> "$OUTPUT_FILE"
fi

## echo "\n } on-error={}" >>"$OUTPUT_FILE"
echo "Conversion complete. Saved to $OUTPUT_FILE"

echo "/ip/firewall/address-list/remove [find where comment=\"$5\" list=\"$4\"]\n/ipv6/firewall/address-list/remove [find where comment=\"$5\" list=\"$4\"]">> $3-cleanup.rsc 