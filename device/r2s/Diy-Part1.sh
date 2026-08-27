#!/bin/bash
# =========================================================
# DIY Script Part 1: 追加第三方 Feeds 软件源
#
# 适用目标:
#   FriendlyARM NanoPi R2S
#   ImmortalWrt 25.12.1
#
# 原则:
#   ImmortalWrt 官方 feeds 已提供的包，不重复添加第三方源。
#   仅追加确有必要且官方源未提供的组件。
# =========================================================

echo "==> [Diy-Part1] 开始检查并追加第三方 Feeds 软件源..."

# ---------------------------------------------------------
# 1. Nikki
# ---------------------------------------------------------
# Nikki 当前作为本固件的主代理组件。
# ImmortalWrt 官方 25.12.1 feeds 不作为当前 Nikki 来源，
# 因此从 Nikki 官方 OpenWrt feed 获取。
#
# 使用 main 分支。
# ---------------------------------------------------------

if ! grep -q "^src-git nikki " feeds.conf.default; then
    echo "==> 追加 Nikki 官方软件源 (main 分支)..."
    echo 'src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main' >> feeds.conf.default
else
    echo "==> Nikki 软件源已存在，跳过追加。"
fi

echo "==> [Diy-Part1] 追加完成！"