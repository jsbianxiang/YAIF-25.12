#!/bin/bash
# =========================================================
# DIY Script Part 1: 追加第三方 Feeds 软件源
# 适用目标: FriendlyARM NanoPi R2S (ImmortalWrt 25.12)
# =========================================================

echo "==> [Diy-Part1] 开始检查并追加第三方 Feeds 软件源..."

# ---------------------------------------------------------
# 1. 追加 Nikki 官方软件源
# ---------------------------------------------------------
# 检查 feeds.conf.default 中是否包含 nikki 关键字；
# 若不存在，追加末尾带 ;main 分支指示符的官方拉取地址。
if ! grep -q "^src-git nikki " feeds.conf.default; then
    echo "==> 追加 Nikki 官方软件源 (main 分支)..."
    echo 'src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main' >> feeds.conf.default
else
    echo "==> Nikki 软件源已存在，跳过追加。"
fi

echo "==> [Diy-Part1] 追加完成！"