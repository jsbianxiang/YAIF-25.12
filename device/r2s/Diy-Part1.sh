#!/bin/bash
# =========================================================
# DIY Script Part 1：追加第三方 Feeds 软件源
#
# 适用目标：
#   FriendlyARM NanoPi R2S
#   ImmortalWrt 25.12.1
#
# 原则：
#   1. ImmortalWrt 官方 feeds 已提供的包，不重复添加第三方源。
#   2. 仅追加确有必要且官方源未提供的组件。
#   3. Nikki 作为本固件主代理组件，使用 Nikki 官方 OpenWrt feed。
# =========================================================

set -euo pipefail

echo "==> [Diy-Part1] 开始检查并追加第三方 Feeds 软件源..."

# ---------------------------------------------------------
# 1. Nikki
# ---------------------------------------------------------
# Nikki 当前作为本固件的主代理组件。
#
# ImmortalWrt 官方 25.12.1 feeds 不作为当前 Nikki 来源，
# 因此使用 Nikki 官方 OpenWrt feed。
#
# 固定使用 main 分支。
# ---------------------------------------------------------

NIKKI_FEED='src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main'

if grep -Fxq "$NIKKI_FEED" feeds.conf.default; then
    echo "==> Nikki 官方软件源已存在，跳过追加。"
else
    # 如果存在旧的 nikki 定义，则先删除，
    # 避免同名 feed 重复定义或指向错误版本。
    if grep -Eq '^src-git nikki ' feeds.conf.default; then
        echo "==> 检测到已有 Nikki 软件源定义，更新为官方 main 分支..."
        sed -i '/^src-git nikki /d' feeds.conf.default
    else
        echo "==> 未检测到 Nikki 软件源。"
    fi

    echo "==> 追加 Nikki 官方软件源（main 分支）..."
    echo "$NIKKI_FEED" >> feeds.conf.default
fi

echo "==> [Diy-Part1] 第三方 Feeds 软件源处理完成。"
