    #!/bin/bash
    # =========================================================
    # DIY Script Part 1：引入第三方软件包源码
    #
    # 适用目标：
    #   FriendlyARM NanoPi R2S
    #   ImmortalWrt 25.12.1
    #
    # 职责：
    #   1. 引入 Clashoo 软件包源码
    #
    # 原则：
    #   - ImmortalWrt 官方 feeds 已提供的软件包，不重复引入。
    #   - Daed 使用 ImmortalWrt 官方 APK 软件源。
    #   - Clashoo 按官方 OpenWrt 安装方式直接引入源码。
    #   - 本脚本不修改 .config。
    #   - 本脚本不负责 APK repository 配置。
    #   - 本脚本不负责软件包选择。
    # =========================================================

    set -euo pipefail

    echo "==> [Diy-Part1] 开始引入第三方软件包源码..."

    # ---------------------------------------------------------
    # 1. Clashoo
    # ---------------------------------------------------------
    #
    # Clashoo 官方仓库：
    #   kenzok8/openwrt-clashoo
    #
    # 仓库包含：
    #   - clashoo
    #   - luci-app-clashoo
    #
    # 按 Clashoo 官方 OpenWrt 安装方式，
    # 直接克隆到 package/openwrt-clashoo。
    # ---------------------------------------------------------

    CLASHOO_REPO="https://github.com/kenzok8/openwrt-clashoo.git"
    CLASHOO_DIR="package/openwrt-clashoo"

    if [ -d "$CLASHOO_DIR/.git" ]; then
        echo "==> Clashoo 源码目录已存在，跳过 clone。"
    else
        if [ -e "$CLASHOO_DIR" ]; then
            echo "ERROR：$CLASHOO_DIR 已存在，但不是 Git 仓库。"
            echo "请检查该目录后重新执行。"
            exit 1
        fi

        echo "==> 正在获取 Clashoo 官方源码..."
        git clone "$CLASHOO_REPO" "$CLASHOO_DIR"
        echo "==> Clashoo 源码引入完成。"
    fi

    echo "==> [Diy-Part1] 第三方软件包源码处理完成。"