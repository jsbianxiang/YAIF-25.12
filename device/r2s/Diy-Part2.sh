#!/bin/bash
# =========================================================
# DIY Script Part 2：R2S 编译前文件注入与预处理
#
# 适用目标：
#   FriendlyARM NanoPi R2S
#   ImmortalWrt 25.12.1
#
# 职责：
#   1. 注入 YAIF 自定义 files/
#   2. 检查 APK repository / key 预置文件
#   3. 清理编译树中的 .orig / .rej 残留文件
#
# 注意：
#   本脚本不修改 .config。
#   本脚本不负责安装 Feeds。
#   本脚本不负责选择软件包。
# =========================================================

set -euo pipefail

echo "==> [Diy-Part2] 开始执行 R2S 编译前预处理..."

# ---------------------------------------------------------
# 1. 注入自定义 files
# ---------------------------------------------------------

if [ -d "../files" ] && find "../files" -mindepth 1 -print -quit | grep -q .
then
    echo "==> 检测到自定义 files，正在注入..."

    mkdir -p ./files

    cp -rf ../files/. ./files/

    # uci-defaults 脚本必须具备可执行权限。
    if [ -d "./files/etc/uci-defaults" ]; then
        find ./files/etc/uci-defaults \
            -type f \
            -exec chmod +x {} +
    fi

    echo "==> 自定义 files 注入完成。"
else
    echo "==> 未发现自定义 files，跳过文件注入。"
fi

# ---------------------------------------------------------
# 2. 检查 APK repository 配置
# ---------------------------------------------------------

echo "==> 检查 APK repository 修复脚本..."

if [ -f "./files/etc/uci-defaults/99-fix-apk-repositories" ]; then
    echo "OK：APK repository fix uci-defaults 已存在。"
else
    echo "WARNING：未发现 APK repository fix uci-defaults。"
fi

echo "==> 检查 APK repository 预置文件..."

if [ -f "./files/etc/apk/repositories.d/customfeeds.list" ]; then
    echo "OK：APK repository 已预置。"
else
    echo "WARNING：未发现 customfeeds.list。"
fi

# ---------------------------------------------------------
# 3. 检查 APK keys
# ---------------------------------------------------------

echo "==> 检查 APK keys 目录..."

if [ -d "./files/etc/apk/keys" ]; then
    echo "OK：APK keys 目录存在。"
else
    echo "WARNING：未发现 APK keys 目录。"
fi

# ---------------------------------------------------------
# 4. 清理补丁残留文件
# ---------------------------------------------------------
# .orig：
#   补丁或文本修改产生的原始文件备份。
#
# .rej：
#   补丁无法正常应用时产生的 rejected hunk 文件。
#
# 这些文件不应进入最终固件构建树。
# ---------------------------------------------------------

echo "==> 清理 .orig / .rej 残留文件..."

find ./ \
    \( -name "*.orig" -o -name "*.rej" \) \
    -type f \
    -print \
    -delete

echo "==> [Diy-Part2] 编译前预处理完成。"
