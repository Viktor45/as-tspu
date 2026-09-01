# AI Agent Instructions for as-tspu

Crowdsourced list of AS numbers affected by TSPU interference. `as-numbers.txt` is the hand-curated source of truth (one ASN per line, ascending numeric order). Everything under `ipverse/` is generated data — never hand-edit it.

## Repository layout

- `as-numbers.txt` — the only hand-maintained data file; contributions go here.
- `ipverse.sh` — POSIX sh script; downloads per-AS IPv4/IPv6 aggregated prefixes from the ipverse/as-ip-blocks repo, removes stale cached files of AS numbers no longer in the list, and merges them into `ipverse/ipv4.txt`, `ipv6.txt`, `merged.txt`, plus `.lst` variants (`asn,cidr` format).
- `agg.sh` — POSIX sh script; fetches the latest `cidrmgr` release binary (Viktor45/cidrmgr) and produces the `ipverse/*-agg.txt` aggregated outputs.
- `ipverse/` — generated lists, committed to the repo; the `ipv4/` and `ipv6/` per-AS subdirectories are gitignored.
- `mikrotik/` — RouterOS helper scripts; their README recommends BGP (`mikrotik/BGP.md`) over these scripts for production.
- `.github/workflows/ipverse.yaml` — runs daily at 01:00 UTC and on every push changing `as-numbers.txt` on `main`; runs both scripts and auto-commits the generated files as `github-actions[bot]` with message "chore: auto-update ipverse data". The job fails if `ipverse/merged.txt` has fewer than 10 lines.

## Key guidance

- The main content is `as-numbers.txt` and the repository README; PRs should touch only `as-numbers.txt`.
- Do not invent or infer additional AS numbers without a reliable source; cite the source for any addition.
- If asked to update the list, preserve the one-entry-per-line format and add only entries supported by citations.
- Do not add unrelated entries, especially from banned categories mentioned in the README (for example, YouTube, Google, or Russian networks).
- Respect the repository's legal notice and the intent of the list: lawful use by telecom operators or users.

## When working in this repository

- Use `README.md` as the authoritative documentation for repository purpose and guidelines.
- There is no build system and no test suite; the shell scripts are the only tooling. Keep them POSIX `sh` compatible (they use `#!/bin/sh`) — CI runs them on ubuntu-latest.
- Generated files under `ipverse/` are refreshed by the daily workflow — edit `as-numbers.txt` and let the workflow regenerate the rest.
- If a task requires code or tooling, first confirm whether the user wants a separate implementation or data maintenance.
- `.github/instructions/` holds markdown and GitHub Actions style rules that apply to edits of `.md` files and workflows.

## What not to do

- Do not change `LICENSE` or metadata without explicit instruction.
- Do not rewrite or reformat `as-numbers.txt` unless needed to preserve consistency.
- Do not add unrelated documentation or tooling files.
- Do not commit the `cidrmgr` binary or the `ipverse/ipv4/` and `ipverse/ipv6/` per-AS directories; they are gitignored local artifacts.
