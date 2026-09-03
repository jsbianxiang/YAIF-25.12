# YAIF-25.12

**Yet Another ImmortalWrt Firmware**

面向 **FriendlyARM NanoPi R2S** 的 ImmortalWrt 25.12.1 长期维护型固件基线。

YAIF 的目标不是制作一个堆叠大量软件的“全家桶固件”，而是在尽可能保持 **ImmortalWrt 原生结构** 的基础上，为 NanoPi R2S 提供一套稳定、可重复构建、可审计、便于长期维护的系统基线。
---
[![Powered by OrcaRouter](https://img.shields.io/badge/Powered_by-OrcaRouter-2563eb)](https://www.orcarouter.ai/ref/ref_a65d058ae35861acbf2f)
---

## 项目定位

YAIF-25.12 基于原生 ImmortalWrt 构建，针对 NanoPi R2S 进行设备、内核、网络及必要软件包适配。

核心思路：

```text
原生 ImmortalWrt
        │
        ├── R2S 硬件适配
        ├── IPv4 / IPv6 双栈
        ├── firewall4 / nftables
        ├── TUN / TProxy 所需内核能力
        ├── Clashoo
        │     ├── Mihomo
        │     └── sing-box
        │
        └── Daed（备用）
```

YAIF 负责提供稳定的系统基础。

代理软件负责具体的代理、DNS、透明代理及流量策略。

两者尽量保持职责分离。

---

# 基础环境

| 项目     | 配置                     |
| ------ | ---------------------- |
| 基础系统   | ImmortalWrt 25.12.1    |
| 上游基线   | ImmortalWrt 25.12      |
| 目标设备   | FriendlyARM NanoPi R2S |
| SoC    | Rockchip RK3328        |
| CPU 架构 | ARM64 / ARMv8          |
| 防火墙    | firewall4 / nftables   |
| 包管理    | APK                    |
| 构建方式   | GitHub Actions         |
| 文件系统   | SquashFS / ext4        |
| IPv4   | NAT                    |
| IPv6   | 原生双栈                   |
| 主代理管理  | Clashoo                |
| 代理内核   | Mihomo / sing-box      |
| 备用代理   | Daed                   |

---

# NanoPi R2S

YAIF 针对 FriendlyARM NanoPi R2S 单独维护构建配置。

R2S：

```text
Rockchip RK3328
ARM64
双千兆以太网
```

项目提供 R2S 专用配置种子及构建流程。

当前仓库结构：

```text
YAIF-25.12/
├── .github/
│   └── workflows/
│       ├── build-r2s.yml
│       └── clean-runs.yml
│
├── device/
│   └── r2s/
│       ├── config.seed
│       ├── Diy-Part1.sh
│       └── Diy-Part2.sh
│
├── files/
│   └── etc/
│       ├── apk/
│       │   └── keys/
│       └── config/
│           └── network
│
├── LICENSE
└── README.md
```

构建配置以 `config.seed` 为主要入口，通过 `make defconfig` 生成最终配置。

这样可以避免长期直接维护完整 `.config`，降低上游版本变化造成的配置漂移。

---

# 网络架构

YAIF 面向二级路由使用场景。

典型网络结构：

```text
                 上级光猫 / 主路由
                         │
                  IPv4 / IPv6
                         │
                         ▼
                ┌────────────────┐
                │   NanoPi R2S   │
                │     YAIF       │
                └───────┬────────┘
                        │
                       LAN
                        │
             ┌──────────┼──────────┐
             │          │          │
            PC        手机       IoT / TV
```

R2S 负责：

* LAN 网关
* IPv4 NAT
* IPv6 路由
* IPv6 Prefix Delegation
* DHCPv4
* IPv6 RA
* firewall4
* nftables
* 代理运行环境

---

# IPv4 / IPv6 双栈

YAIF 不通过关闭 IPv6 来解决代理兼容性问题。

系统保持原生 IPv4 / IPv6 双栈能力。

IPv4：

```text
LAN
 │
 ▼
R2S
 │
 └── NAT
      │
      ▼
    WAN
```

IPv6：

```text
上游 IPv6 / DHCPv6-PD
          │
          ▼
         R2S
          │
          ▼
       LAN /64
          │
          ▼
       LAN 客户端
```

IPv6 负责原生网络连通性。

代理软件根据实际代理策略决定哪些 IPv6 流量进入代理。

---

# firewall4 / nftables

YAIF 使用 ImmortalWrt 25.12 原生的：

```text
firewall4
    │
    └── nftables
```

不以 legacy iptables / ip6tables 作为基础防火墙体系。

系统保留透明代理所需的相关 Netfilter 能力，包括：

```text
kmod-nft-socket
kmod-nft-tproxy
kmod-tun
kmod-dummy
kmod-inet-diag
ip-full
```

这些组件也是 Clashoo 官方列出的透明代理运行依赖。

---

# Clashoo

YAIF 当前主要代理管理方案为 **Clashoo**。

Clashoo 是面向 OpenWrt 的双内核代理管理插件，而不是单独的代理内核。

官方支持：

```text
Clashoo
│
├── Mihomo
│    ├── Stable
│    ├── Alpha
│    └── Smart
│
└── sing-box
     ├── Stable
     └── Alpha
```

Clashoo 支持在 LuCI 中切换代理内核，并使用统一的 UCI 配置适配不同内核。内核切换无需重新安装插件。

官方项目：

https://github.com/kenzok8/openwrt-clashoo

---

# Clashoo 透明代理

透明代理由 Clashoo 负责具体管理。

官方支持：

### TCP

```text
Redirect
TProxy
TUN
```

### UDP

```text
TProxy
TUN
```

### TUN 网络栈

```text
gVisor
System
Mixed
```

具体模式属于运行时代理配置，而不是 YAIF 固件构建阶段固定的网络策略。

因此 YAIF 的职责主要是：

```text
Linux 内核
    │
    ├── TUN
    ├── Netfilter
    ├── nftables
    ├── TProxy
    └── socket
          │
          ▼
       Clashoo
          │
          ▼
   Mihomo / sing-box
```

而不是在 YAIF 中硬编码具体代理规则。

---

# Clashoo DNS

Clashoo 本身提供完整的 DNS 管理能力，包括：

* Fake-IP
* Redir-Host
* 默认 / 代理 / 直连 / Fallback DNS
* Bootstrap DNS
* Fallback GeoIP
* ECS
* DNS 防泄漏
* DoT / DoQ 阻断
* 国内域名规则集

因此 YAIF 的基础网络配置不会试图复制 Clashoo 的 DNS 策略。

具体 DNS 行为由 Clashoo / Mihomo / sing-box 的运行时配置决定。

---

# Daed

YAIF **继续保留 Daed**。

Daed 不作为 Clashoo 的替代品，而作为备用代理方案。

定位：

```text
                 YAIF
                   │
          ┌────────┴────────┐
          │                 │
       Clashoo             Daed
        主方案             备用方案
          │
     ┌────┴────┐
  Mihomo   sing-box
```

两者不要求同时运行。

保留 Daed 的主要原因是：

* 性能表现优秀
* 配置简单
* 可以作为备用代理环境
* 与 Clashoo / Mihomo 的规则体系存在差异
* 当主代理方案出现问题时，可以快速切换进行验证

---

# FullCone NAT

YAIF 保留 FullCone NAT 支持。

IPv4：

```text
FullCone NAT
```

主要面向：

* P2P
* UDP
* NAT 穿透
* 实时通信
* 部分特殊应用

IPv6 则保持原生 IPv6 路由。

IPv6 是否使用 FullCone 相关能力属于运行环境策略，不作为 IPv4 NAT 的简单复制。

---

# Flow Offloading

YAIF 默认关闭：

```text
Software Flow Offloading
Hardware Flow Offloading
```

原因是透明代理环境需要保证流量能够正常经过：

```text
Netfilter
TProxy
TUN
socket
policy routing
```

对于 R2S 这样的透明代理网关：

> **优先保证流量路径正确和代理稳定，而不是单纯追求最高 NAT 转发吞吐量。**

---

# IPv6 ICMP

YAIF 保留 IPv6 正常运行所需要的 ICMPv6。

包括：

* Echo Request / Reply
* Destination Unreachable
* Packet Too Big
* Time Exceeded
* Bad Header
* Unknown Header Type
* Neighbor Discovery
* Router Solicitation
* Router Advertisement

其中 `Packet Too Big` 对 IPv6 Path MTU Discovery 尤其重要。

因此 YAIF 不采用“为了代理稳定而全面阻断 ICMPv6”的方案。

---

# DHCP / RA

LAN DHCPv4 由 dnsmasq 提供。

IPv6 则由 odhcpd 提供：

```text
DHCPv6
RA
ND
```

典型结构：

```text
WAN6
 │
 └── DHCPv6 / Prefix Delegation
             │
             ▼
            R2S
             │
             ▼
          LAN /64
             │
             ▼
        IPv6 RA 客户端
```

IPv6 地址分配和路由通告属于系统网络层职责。

代理 DNS 策略属于 Clashoo / Mihomo / sing-box 职责。

---

# DNS 设计原则

YAIF 将：

```text
网络地址分配
```

与：

```text
代理 DNS
```

进行解耦。

系统层：

```text
dnsmasq
odhcpd
```

负责：

* DHCPv4
* 本地域名
* LAN 地址
* IPv6 RA

代理层：

```text
Clashoo
   │
Mihomo / sing-box
```

负责：

* DNS 分流
* Fake-IP / Redir-Host
* 代理 DNS
* DNS 防泄漏
* DNS 劫持

这样可以避免把具体代理规则固化到 YAIF 基础系统。

---

# BBR

YAIF 保留 Linux BBR 所需内核能力。

BBR 的运行时参数不强制写死在固件构建阶段。

这样可以根据实际线路和网络环境进行调整，而无需重新编译固件。

---

# ZRAM

R2S 保留 ZRAM 相关能力。

主要用于在资源压力较高时提供压缩交换空间。

ZRAM 的具体运行参数属于系统运行时配置，不作为固件构建阶段永久固定的网络策略。

---

# 构建系统

YAIF 使用 GitHub Actions 构建。

基本流程：

```text
Clone ImmortalWrt 25.12.1
          │
          ▼
      更新 feeds
          │
          ▼
    加入第三方组件
          │
          ▼
      注入文件
          │
          ▼
    应用 R2S config.seed
          │
          ▼
     make defconfig
          │
          ▼
       配置检查
          │
          ▼
        编译
          │
          ▼
     构建结果检查
          │
          ▼
       Firmware
```

构建过程尽可能保持可重复、可审计。

---

# 配置维护原则

YAIF 长期维护遵循以下原则。

### 1. 原生优先

尽可能保持 ImmortalWrt 官方默认行为。

### 2. 必要修改

只有存在明确需求时才修改默认配置。

### 3. 不追求参数堆叠

不会因为某个参数“理论上更快”就加入基线。

### 4. 系统与代理解耦

YAIF 提供代理运行环境。

Clashoo 负责代理运行策略。

### 5. IPv6 保持完整能力

不通过关闭 IPv6 解决代理问题。

### 6. 配置可审计

每一项非默认配置都应该能够解释原因。

### 7. 长期维护优先

优先考虑稳定、兼容和后续升级，而不是短期极限性能。

---

# 软件包原则

YAIF 不追求预装大量软件。

软件包主要分为：

```text
基础系统
│
├── ImmortalWrt 原生组件
│
├── R2S 硬件支持
│
├── 网络 / IPv6
│
├── firewall4 / nftables
│
├── 透明代理基础能力
│
├── Clashoo
│
└── Daed
```

具体软件包以 `config.seed` 和构建结果为准。

不会仅因为某个软件“可能有用”就加入长期固件基线。

---

# 项目结构

```text
YAIF-25.12/
│
├── .github/
│   └── workflows/
│       ├── build-r2s.yml
│       └── clean-runs.yml
│
├── device/
│   └── r2s/
│       ├── config.seed
│       ├── Diy-Part1.sh
│       └── Diy-Part2.sh
│
├── files/
│   └── etc/
│       ├── apk/
│       │   └── keys/
│       └── config/
│           └── network
│
├── LICENSE
└── README.md
```

---

# 构建与使用

本项目主要面向已经熟悉 ImmortalWrt / OpenWrt 的用户。

构建完成后：

1. 下载对应 NanoPi R2S 固件。
2. 刷写或升级 ImmortalWrt。
3. 根据实际网络环境配置 WAN / LAN。
4. 配置 IPv6 / DHCPv6-PD。
5. 安装或启用 Clashoo。
6. 选择 Mihomo 或 sing-box 内核。
7. 导入代理订阅或配置文件。
8. 根据实际需求配置 TCP / UDP / TUN。
9. 根据需要保留 Daed 作为备用代理方案。

Clashoo 的具体安装、内核下载、配置管理和透明代理设置请参考其官方项目文档。

---

# 上游项目

* ImmortalWrt
  https://github.com/immortalwrt/immortalwrt

* Clashoo
  https://github.com/kenzok8/openwrt-clashoo

* Mihomo
  https://github.com/MetaCubeX/mihomo

* sing-box
  https://github.com/SagerNet/sing-box

* Daed
  https://github.com/daeuniverse/daed

---

# License

本项目采用 GPL-3.0 License。

第三方组件遵循各自项目的开源许可证及版权声明。
---
