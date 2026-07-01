# BGP Configuration Guide: MikroTik RouterOS 7 and WDBGP

This guide provides detailed instructions for configuring BGP routing on MikroTik RouterOS 7 in conjunction with a self-hosted WDBGP server. 

> **WARNING:** This document serves as a reference implementation. Adapt the configuration to your specific network requirements. **Always enable `Safe Mode`** on the production router before applying changes to prevent accidental loss of access.

---

## Table of Contents
- [BGP Configuration Guide: MikroTik RouterOS 7 and WDBGP](#bgp-configuration-guide-mikrotik-routeros-7-and-wdbgp)
  - [Table of Contents](#table-of-contents)
  - [1. Recommended Software](#1-recommended-software)
  - [2. WDBGP Configuration: Custom Adapter](#2-wdbgp-configuration-custom-adapter)
  - [3. MikroTik RouterOS 7 Routing Configuration](#3-mikrotik-routeros-7-routing-configuration)
    - [3.1. Routing Table Creation](#31-routing-table-creation)
    - [3.2. Routing Rules Configuration](#32-routing-rules-configuration)
    - [3.3. Community Filtering (Optional / Advanced)](#33-community-filtering-optional--advanced)
    - [3.4. Filter Rules (Optional / Advanced)](#34-filter-rules-optional--advanced)
  - [4. MikroTik to WDBGP Integration](#4-mikrotik-to-wdbgp-integration)
    - [4.1. BGP Instance Creation](#41-bgp-instance-creation)
    - [4.2. BGP Connection Configuration](#42-bgp-connection-configuration)
  - [5. Troubleshooting](#5-troubleshooting)

---

## 1. Recommended Software
For the self-hosted BGP server, we recommend:
* [WDBGP](https://github.com/andrey-vk/wdbgp/)

---

## 2. WDBGP Configuration: Custom Adapter
To add a custom adapter for `as-tspu`, navigate to **Admin -> Adapters** in the WDBGP interface and apply the following JavaScript script:

```javascript
function sync(feed, api) {
  const result = []
  var url = 'https://raw.githubusercontent.com/viktor45/as-tspu/refs/heads/main/ipverse/merged.lst'
  
  var response = api.httpGet(url)
  if (!response) return result

  let services = response.split(/\r?\n/)

  services.forEach(item => {
    const trimmed = item.trim()
    if (!trimmed) return 

    const parts = trimmed.split(',')
    if (parts.length < 2) return 

    const asNumber = parts[0].trim()
    const cidr = parts[1].trim()

    result.push({
      category: 'tspu',
      service: asNumber,
      cidrs: [cidr] 
    })
  })

  return result
}
```
> **Note:** Ensure that community numbers are configured in **Admin -> Communities**, and enable the required directory and feed for your client (the router).

---

## 3. MikroTik RouterOS 7 Routing Configuration

### 3.1. Routing Table Creation
The following settings are mandatory. A dedicated routing table for BGP routes must be created.

* `table-bgp` is our routing table for BGP routes.

```sh
# Create a routing table for BGP routes. The 'fib' parameter is mandatory.
/routing table
add comment="BGP TABLE" disabled=no fib name=table-bgp
```
> **CRITICAL WARNING:** The `table-bgp` routing table **MUST NOT** contain a default route.

### 3.2. Routing Rules Configuration
The following settings are mandatory. These rules define the traffic routing logic.

* IMPORTANT: Replace `LAN_INTERFACE` with the actual name of your local interface or bridge.
* If multiple local interfaces exist, create a corresponding rule for each.

```sh
# 1. Allow local traffic (between local subnets) to be routed via the main table.
/routing rule
add action=lookup comment="local LAN traffic" disabled=no min-prefix=0 table=main

# 2. Direct all traffic from the LAN interface to be evaluated against the table-bgp.
# Action=lookup: if the prefix exists in table-bgp, route it there; otherwise, fall back to the main table.
add action=lookup chain=user comment="send all LAN bridge to table-bgp" disabled=no interface=LAN_INTERFACE \
    table=table-bgp
```

### 3.3. Community Filtering (Optional / Advanced)
*These settings are optional and provided as a reference for advanced users.*

You can define custom `large-community-set` configurations (e.g., `174,13335`). Ensure these communities are named appropriately in the WDBGP **Admin -> Communities** interface.

* `large_bgp_filter` is our list for large communities.

```sh
# Create a list to configure gateways based on communities (optional)
/routing filter community-large-list
add communities=64512:0:174,64512:0:13335 disabled=no list=large_bgp_filter
```

### 3.4. Filter Rules (Optional / Advanced)
*Example rule for distributing traffic across different gateways based on BGP communities.*

* Replace `IPV6_GATEWAY`, `CUSTOM_GATEWAY1`, and `CUSTOM_GATEWAY2` with your actual gateway addresses. Modify as you need;
* `large_bgp_filter` refers to the community list created in the previous step.


```sh
# We are adding filter rule
/routing filter rule
add chain=filter_chain disabled=no rule="if(afi ipv6) { set \
    \ngw IPV6_GATEWAY; accept; } else { if (bgp-large-communities includes-list large_bgp_filter) { set gw CUSTOM_GATEWAY1; set\
    \_comment \
    \nCUSTOM1;} else { set gw CUSTOM_GATEWAY2; set comment CUSTOM2;}  set distance 3; accept;}"
```

---

## 4. MikroTik to WDBGP Integration

### 4.1. BGP Instance Creation

The following settings are mandatory.

* IMPORTANT: Replace `ROUTER_IP` with the IP address of your MikroTik router;
* `64999` - our MikroTik router AS.

```sh
/routing bgp instance
# Create the BGP instance.
add as=64999 disabled=no name=MY_INSTANCE router-id=ROUTER_IP
```

### 4.2. BGP Connection Configuration
The following settings are mandatory. This configures the filters and the connection to the WDBGP server.


* `MY_CONNECTION` is the connection name. Ensure it is enabled after configuring the server;
* IMPORTANT: Replace `ROUTER_IP` with your MikroTik IP;
* IMPORTANT: Replace `BGP_SERVER_IP` with your WDBGP server IP;
* `64512` - WDBGP server AS;
* `64999` - our MikroTik router AS;
* `filter_chain` - is our main filtering rule, see before for an example;
* `table-bgp` is our routing table for BGP routes.

```sh
# Configure filter: do not advertise local routes back to the WDBGP server.
/routing filter rule
add chain=discard disabled=no rule="reject;"

/routing bgp connection
# Establish the connection to the WDBGP server.
add afi=ip,ipv6 as=64999 disabled=no hold-time=4m input.filter=filter_chain instance=\
    MY_INSTANCE keepalive-time=1m local.address=ROUTER_IP .role=ebgp-peer multihop=yes name=\
    MY_CONNECTION output.filter-chain=discard .network=bgp-networks .no-client-to-client-reflection=yes \
    remote.address=BGP_SERVER_IP/32 .as=64512 routing-table=table-bgp
```

> **Final Step:** Remember to add the adapter and the client (using `ROUTER_IP`) within the WDBGP configuration.

---

## 5. Troubleshooting

If you encounter issues or unexpected traffic routing behavior:
1. **Consult the WDBGP Documentation:** Review the official documentation for specific server-side nuances.
2. **Review System Logs:** Enable logging on both WDBGP and MikroTik to trace the exact point of failure.
3. **Reset the Connection:** Try disabling and subsequently re-enabling the `MY_CONNECTION` BGP connection.
4. **Verify Prefixes:** Ensure that the expected prefixes are successfully received from the WDBGP server **Admin -> Clients -> Client -> Service Selection**.
