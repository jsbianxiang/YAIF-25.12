# YAIF-25.12

**Yet Another ImmortalWrt Firmware**

面向 **FriendlyARM NanoPi R2S** 的 ImmortalWrt 25.12.1 长期维护型固件构建项目。

本项目坚持使用接近原生的 **ImmortalWrt** 作为基础，通过独立的 R2S `config.seed`、自定义 Feeds、文件注入和 GitHub Actions 构建工作流，生成可重复、可审计、便于长期维护的 NanoPi R2S 固件。

> **项目目标不是堆叠功能，而是在保持 ImmortalWrt 原生结构的基础上，为 NanoPi R2S 建立稳定、清晰、可维护的固件基线。**

---

## 项目状态

| 项目      | 状态                     |
| ------- | ---------------------- |
| 基础系统    | ImmortalWrt 25.12.1    |
| 上游基线    | ImmortalWrt 25.12      |
| 硬件      | FriendlyARM NanoPi R2S |
| SoC     | Rockchip RK3328        |
| 架构      | ARM64 / Rockchip ARMv8 |
| 构建平台    | GitHub Actions         |
| 构建环境    | Ubuntu 24.04           |
| 包管理器    | APK                    |
| 主代理     | Nikki + Mihomo Meta    |
| 备用代理    | Daed                   |
| 文件系统    | SquashFS / ext4        |
| 构建方式    | GitHub Actions 手动触发    |
| License | GPL-3.0                |

---

# 主要特点

## 1. 原生 ImmortalWrt 基线

项目直接基于固定版本的 ImmortalWrt 25.12.1 构建，不以其他第三方固件作为二次基础。

这样做的主要目的：

* 保持与 ImmortalWrt 上游结构的一致性
* 降低长期维护成本
* 减少第三方 Patch 对系统的侵入
* 方便后续跟踪上游修复
* 便于通过 `diffconfig` 和最终 `.config` 对配置进行审计

ImmortalWrt 版本在构建工作流中固定：

```text
ImmortalWrt 25.12.1
```

不会因为默认分支更新而自动漂移。

---

# 2. NanoPi R2S 专用配置

本项目针对：

```text
FriendlyARM NanoPi R2S
Rockchip RK3328
ARM64
```

提供独立配置种子：

```text
device/r2s/config.seed
```

构建过程中：

```text
config.seed
    ↓
make defconfig
    ↓
最终 .config
```

而不是直接维护一个未经处理的最终 `.config`。

这样可以让 R2S 的功能选择、内核配置和软件包配置保持集中管理。

---

# 3. Nikki + Mihomo Meta

项目默认代理架构：

```text
Nikki
  ↓
Mihomo Meta
  ↓
TUN / TProxy
```

Nikki 软件源单独维护，并在构建过程中记录 Feed Commit。

当前使用：

```text
nikki
luci-app-nikki
mihomo-meta
```

`mihomo-alpha` 虽然存在于 Nikki Feed 中，但本项目明确不启用 Alpha 版本，以避免与 Mihomo Meta 产生不必要的包依赖和配置冲突。

---

# 4. Daed 备用代理

除 Nikki 外，同时提供 Daed：

```text
daed
luci-app-daed
luci-i18n-daed-zh-cn
```

Daed 作为备用代理方案保留，而不是与 Nikki 同时承担主代理职责。

这样可以在需要时切换代理内核，而不需要重新设计整个固件基础。

---

# 5. IPv6

IPv6 保持启用。

项目并不采用简单粗暴的“完全关闭 IPv6”方案，而是保留完整的 IPv6 网络能力，使 R2S 可以正常工作于 IPv4 / IPv6 双栈网络环境。

具体的 IPv6 策略、DNS 策略和代理规则由运行时配置负责，而不是在固件构建阶段强制关闭 IPv6。

---

# 6. nftables / FullCone / TProxy

固件基于 ImmortalWrt 25.12 的 nftables 防火墙体系。

重点保留：

* firewall4
* nftables
* nftables JSON
* nft TProxy
* nft socket
* nft FullCone
* Netfilter connection tracking
* NAT
* Flow / connection tracking 相关内核模块

传统 iptables legacy 体系不作为本项目的基础。

---

# 7. BPF / BTF

内核保留较完整的 BPF / BTF 能力，包括：

* BPF toolchain
* DWARVES
* Kernel BPF events
* Kernel BPF stream parser
* cgroups
* Kprobes
* Netkit
* XDP sockets
* BPF / BTF debug information
* BTF module support
* XDP socket diagnostics
* sched-bpf

这些配置并不是为了单纯追求“功能数量”，而是作为长期维护内核时的基础能力保留。

---

# 8. 内核与网络能力

项目保留 NanoPi R2S 网络代理环境所需要的相关内核模块，包括：

### TUN / TProxy

```text
kmod-tun
kmod-dummy
kmod-inet-diag
kmod-nft-socket
kmod-nft-tproxy
```

### Connection Tracking

```text
kmod-nf-conntrack
kmod-nf-conntrack6
kmod-nf-conntrack-netlink
kmod-nf-nat
kmod-nft-nat
```

### FullCone / Offload

```text
kmod-nft-fullcone
kmod-nft-offload
kmod-nf-flow
```

### BBR

```text
kmod-tcp-bbr
```

---

# 9. BBR / ZRAM

项目默认保留：

```text
kmod-tcp-bbr
zram-swap
```

以及 ZRAM 所需要的压缩算法模块：

```text
kmod-lib-lz4
kmod-lib-lzo
kmod-lib-zstd
```

运行时具体的 TCP 拥塞控制和 ZRAM 参数属于系统运行配置，不通过固件编译阶段强行写死。

---

# 10. SquashFS + ext4

项目同时构建两种系统镜像：

### SquashFS

适合作为长期运行的推荐版本：

```text
immortalwrt-rockchip-armv8-friendlyarm_nanopi-r2s-squashfs-sysupgrade.img.gz
```

### ext4

提供可写系统：

```text
immortalwrt-rockchip-armv8-friendlyarm_nanopi-r2s-ext4-sysupgrade.img.gz
```

两种文件系统各有用途，不强制所有用户使用同一种方案。

---

# 构建系统

项目完全通过 GitHub Actions 构建。

核心工作流：

```text
.github/workflows/
└── build-r2s.yml
```

构建流程大致如下：

```text
Checkout YAIF
      ↓
安装构建依赖
      ↓
检查构建环境
      ↓
固定 Clone ImmortalWrt 25.12.1
      ↓
添加 YAIF / Nikki Feed
      ↓
更新并安装 Feeds
      ↓
验证 Nikki Feed
      ↓
注入 YAIF 自定义文件
      ↓
应用 device/r2s/config.seed
      ↓
make defconfig
      ↓
验证最终 .config
      ↓
检查禁止配置
      ↓
生成 diffconfig
      ↓
保存构建状态
      ↓
make download
      ↓
完整编译
      ↓
验证 R2S 固件
      ↓
SHA256 校验
      ↓
生成 Artifact
      ↓
可选 GitHub Release
```

---

# 构建参数审计

本项目并不是简单执行：

```bash
make
```

而是在实际编译前对最终 `.config` 进行多层检查。

包括：

* CONFIG 重复项检查
* `config.seed` 选择检查
* 明确禁用配置检查
* 禁止配置检查
* Target / Subtarget / Device 检查
* 固件分区大小检查
* IPv6 检查
* Nikki 检查
* Daed 检查
* firewall4 / nftables 检查
* TUN / TProxy 检查
* Netfilter 检查
* FullCone 检查
* BPF / BTF 检查
* Crypto 依赖检查
* BBR / ZRAM 检查

如果最终 `.config` 与项目预期不一致，构建会在真正编译前直接失败。

---

# Target

NanoPi R2S 使用：

```text
Target:
    rockchip

Subtarget:
    rockchip / armv8

Device:
    friendlyarm_nanopi-r2s
```

对应构建配置：

```text
CONFIG_TARGET_rockchip=y
CONFIG_TARGET_rockchip_armv8=y
CONFIG_TARGET_rockchip_armv8_DEVICE_friendlyarm_nanopi-r2s=y
```

固件输出目录：

```text
bin/targets/rockchip/armv8/
```

---

# 固件布局

当前 R2S 基线：

```text
Kernel partition:
    64 MB

RootFS partition:
    1024 MB
```

同时生成：

```text
SquashFS
ext4
gzip compressed images
```

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
│       └── config/
│
├── LICENSE
└── README.md
```

### `config.seed`

R2S 的核心配置入口。

负责：

* Target
* Kernel
* 软件包
* 网络相关内核模块
* BPF / BTF
* BBR
* ZRAM
* Nikki
* Daed
* 其他固件功能

---

### `Diy-Part1.sh`

在 Feeds 更新之前执行。

主要负责：

* 添加 YAIF 自定义软件源
* 配置 Nikki Feed
* 准备构建所需的软件源环境

---

### `Diy-Part2.sh`

在 Feeds 安装之后执行。

主要负责：

* 注入自定义文件
* 默认系统配置
* 网络配置
* 防火墙相关配置
* 固件版本相关内容
* 其他构建阶段需要注入的文件

---

# 构建产物

成功构建后会生成两类 Artifact。

## Build State

包含：

```text
YAIF-R2S-final.config
YAIF-R2S-diffconfig
YAIF-source-revisions.txt
YAIF-feeds.conf
YAIF-feeds-runtime.conf
YAIF-feeds-runtime-dir.tar.gz
device/r2s/config.seed
```

用于长期保存构建环境和配置基线。

---

## Firmware

包含：

```text
*.squashfs-sysupgrade.img.gz
*.ext4-sysupgrade.img.gz
sha256sums
config.buildinfo
feeds.buildinfo
*.manifest
YAIF-R2S.config
YAIF-R2S-diffconfig
YAIF-source-revisions.txt
YAIF-feeds-runtime.conf
```

这些文件可以帮助确认：

* 使用了哪个 ImmortalWrt Commit
* 使用了哪个 Nikki Feed Commit
* 使用了什么最终配置
* 构建时启用了哪些软件包
* 固件对应哪个 GitHub Actions Run

---

# 如何构建

进入 GitHub 仓库：

[YAIF-25.12](https://github.com/jsbianxiang/YAIF-25.12?utm_source=chatgpt.com)

进入：

```text
Actions
  ↓
Build ImmortalWrt 25.12.1 for NanoPi R2S
  ↓
Run workflow
```

可选择：

```text
ssh
```

开启 SSH 调试。

也可以选择：

```text
release
```

构建成功后自动创建 GitHub Release。

---

# 下载固件

构建成功后，可以从 GitHub Actions 的 Artifact 获取固件。

如果启用了 Release，则可以直接从：

[YAIF-25.12 Releases](https://github.com/jsbianxiang/YAIF-25.12/releases?utm_source=chatgpt.com)

获取对应版本。

刷写前建议使用项目提供的：

```text
sha256sums
```

验证文件完整性。

---

# 长期维护原则

YAIF 不追求频繁追新版本，而强调：

### 1. 固定基础版本

构建工作流明确固定：

```text
ImmortalWrt 25.12.1
```

避免构建环境无意漂移。

### 2. 配置集中管理

R2S 配置集中在：

```text
device/r2s/config.seed
```

避免大量散落的配置修改。

### 3. 保持上游结构

尽可能使用 ImmortalWrt 原生机制，而不是大量修改底层源码。

### 4. 构建结果可追溯

每次构建记录：

```text
YAIF Commit
ImmortalWrt Commit
Nikki Feed Commit
GitHub Run Number
GitHub Run ID
```

### 5. 先验证，再编译

最终 `.config` 不符合预期时，构建应该在真正编译之前失败。

---

# 关于性能

NanoPi R2S 使用 Rockchip RK3328 ARM64 平台。

YAIF 不宣称某个固定的“千兆跑满”或固定测速结果。

实际性能会受到：

* 网络协议
* PPPoE
* IPv4 / IPv6
* TUN / TProxy
* DNS
* 代理协议
* 加密方式
* 连接数
* MTU
* 防火墙规则
* CPU 负载
* 温度

等因素影响。

因此，本项目更关注：

> **稳定性、可维护性、配置透明度和长期可复现性。**

---

# 注意事项

1. 本项目面向熟悉 OpenWrt / ImmortalWrt 的用户。
2. 固件中的代理软件及相关配置仅作为网络工具使用。
3. 不同网络环境可能需要调整运行时配置。
4. 刷写固件前请确认设备型号为 **NanoPi R2S**。
5. 刷写前建议备份当前配置。
6. 固件升级、恢复和配置迁移产生的问题需要结合实际环境判断。
7. 不建议未经验证直接把 R2S 配置用于其他 Rockchip 设备。

---

# 上游项目

本项目基于以下开源项目：

* [ImmortalWrt](https://github.com/immortalwrt/immortalwrt?utm_source=chatgpt.com)
* [Nikki](https://github.com/nikkinikki-org/nikki?utm_source=chatgpt.com)

感谢所有上游项目及开源社区贡献者。

---

# License

本项目采用：

**GPL-3.0**

具体许可证内容请参见：

```text
LICENSE
```

本项目中的第三方组件分别遵循其各自的开源许可证。

---

# Disclaimer

本项目为个人维护的固件构建项目。

YAIF 不代表 ImmortalWrt 官方，也不代表 FriendlyARM 官方。

使用本项目构建或刷写固件前，请自行确认设备、配置和网络环境。

**使用风险由使用者自行承担。**
