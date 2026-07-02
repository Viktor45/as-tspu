# as-tspu
Crowdsourced list of AS numbers affected by TSPU interference

<!-- TOC -->
- [as-tspu](#as-tspu)
  - [Purpose of the list](#purpose-of-the-list)
  - [Download](#download)
  - [Contributing guidelines](#contributing-guidelines)
  - [IPVerse data generation](#ipverse-data-generation)
  - [Legal notice](#legal-notice)
<!-- TOC -->

## Purpose of the list
This list aims to simplify for end users the list of networks whose access must be corrected due to interference from TSPU equipment. 

This list generation tool can also be used to prepare any other AS lists. Simply fork the repository and populate the AS list file `as-numbers.txt` with your own dataset, and don't forget to update the list links yourself if necessary.

## Download

The lists can be downloaded here:

| list      | version    | filename         | download link                                                                                                 |
| --------- | ---------- | ---------------- | ------------------------------------------------------------------------------------------------------------- |
| ASN       | text       | `as-numbers.txt` | [💾 as-numbers.txt](https://raw.githubusercontent.com/Viktor45/as-tspu/refs/heads/main/as-numbers.txt)         |
| IPv4      | as-is      | `ipv4.txt`       | [💾 ipv4.txt](https://raw.githubusercontent.com/Viktor45/as-tspu/refs/heads/main/ipverse/ipv4.txt)             |
| IPv6      | as-is      | `ipv6.txt`       | [💾 ipv6.txt](https://raw.githubusercontent.com/Viktor45/as-tspu/refs/heads/main/ipverse/ipv6.txt)             |
| IPv4+IPv6 | as-is      | `merged.txt`     | [💾 merged.txt](https://raw.githubusercontent.com/Viktor45/as-tspu/refs/heads/main/ipverse/merged.txt)         |
| IPv4      | lst        | `ipv4.lst`       | [💾 ipv4.lst](https://raw.githubusercontent.com/Viktor45/as-tspu/refs/heads/main/ipverse/ipv4.lst)             |
| IPv6      | lst        | `ipv6.lst`       | [💾 ipv6.lst](https://raw.githubusercontent.com/Viktor45/as-tspu/refs/heads/main/ipverse/ipv6.lst)             |
| IPv4+IPv6 | lst        | `merged.lst`     | [💾 merged.lst](https://raw.githubusercontent.com/Viktor45/as-tspu/refs/heads/main/ipverse/merged.lst)         |
| IPv4      | aggregated | `ipv4-agg.txt`   | [💾 ipv4-agg.txt](https://raw.githubusercontent.com/Viktor45/as-tspu/refs/heads/main/ipverse/ipv4-agg.txt)     |
| IPv6      | aggregated | `ipv6-agg.txt`   | [💾 ipv6-agg.txt](https://raw.githubusercontent.com/Viktor45/as-tspu/refs/heads/main/ipverse/ipv6-agg.txt)     |
| IPv4+IPv6 | aggregated | `merged-agg.txt` | [💾 merged-agg.txt](https://raw.githubusercontent.com/Viktor45/as-tspu/refs/heads/main/ipverse/merged-agg.txt) |


Please note:
* The **as-is** version contains ASN and IP data provided in the ipverse repository.
* The **lst** version has the string format `as_number,ip_cidr`.
* The **aggregated** version contains only aggregated IP/CIDR data without comments.


## Contributing guidelines

Additions to the list are welcome. 

Simple rules for the list:

The following resources are welcome:
* Foreign hosting providers;
* CDN resources.

Do not add to the list:
* YouTube, Google, etc.
* Russian resources and networks.

Create an issue or submit a PR to `as-numbers.txt`. 
Other files are generated automatically every 8 hours.
Please be sure to cite the source.

## IPVerse data generation

This repository includes [ipverse.sh](ipverse.sh), a helper script that downloads IPv4 and IPv6 aggregated prefix lists for each AS in `as-numbers.txt` from the [ipverse/as-ip-blocks](https://github.com/ipverse/as-ip-blocks/) repository.

Running `sh ipverse.sh` will:
* create an `ipverse` folder
* download per-AS `ipv4-aggregated.txt` files to `ipverse/ipv4/{AS}.txt`
* download per-AS `ipv6-aggregated.txt` files to `ipverse/ipv6/{AS}.txt`
* merge all IPv4 files into `ipverse/ipv4.txt`
* merge all IPv6 files into `ipverse/ipv6.txt`
* combine both into `ipverse/merged.txt`

This repository also includes [agg.sh](agg.sh), which downloads the latest `cidrmgr` binary release for the current OS/architecture and aggregates the generated IP lists.

Running `sh agg.sh` will:
* download the latest [Viktor45/cidrmgr](https://github.com/Viktor45/cidrmgr) release asset for the current OS/architecture
* extract the `cidrmgr` binary
* run `cidrmgr merge -i ipverse/ipv4.txt -o ipverse/ipv4-agg.txt`
* run `cidrmgr merge -i ipverse/ipv6.txt -o ipverse/ipv6-agg.txt`
* merge both aggregated outputs into `ipverse/merged-agg.txt`

## Legal notice
This list may be used by any telecom operators or users for any lawful purposes.

---

Sources:
* https://hyperion-cs.github.io/dpi-checkers/
* https://ntc.party/t/блокировка-cloudflare-ovh-hetzner-digitalocean-09062025-xxxxxxxx/17013/682
* https://github.com/123jjck/cdn-ip-ranges/
* https://habr.com/ru/articles/1010336/