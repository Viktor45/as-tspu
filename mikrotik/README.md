# MikroTik helpers

Scripts in this folder help import the generated as-tspu lists into MikroTik RouterOS.

Using these scripts in a production environment is not recommended. Use [BGP](BGP.md) with routing tables instead.

## fast-mikrotik.sh

Converts the aggregated `ipverse/ipv4-agg.txt` and `ipverse/ipv6-agg.txt` lists into a RouterOS `.rsc` import script that fills `/ip` and `/ipv6 firewall address-list` entries.

Usage:

```sh
./fast-mikrotik.sh <ipv4_file> <ipv6_file> <output_file> <listname> <comment>
```

Example:

```sh
./fast-mikrotik.sh ../ipverse/ipv4-agg.txt ../ipverse/ipv6-agg.txt tspu-list bypass TSPU
```

This creates `tspu-list.rsc` for import on the router and `tspu-list-cleanup.rsc`, which removes the added address-list entries.

Import on the router: `/import tspu-list.rsc`.

## slow-routeros.rsc

A self-contained RouterOS script that downloads one of the generated lists directly on the router (via `/tool fetch`), parses it, and fills the address-lists. Edit the variables at the top of the script (`targetComment`, `listName`, `tmpPath`, `url`) before use, then import it.

As the name suggests, parsing large files is slow on low-end routers — prefer `fast-mikrotik.sh` or the [BGP setup](BGP.md).
