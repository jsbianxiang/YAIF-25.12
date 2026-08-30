#!/bin/bash
# =========================================================
# DIY Script Part 2：R2S 编译前文件注入与 APK 源准备
#
# 适用目标：
#   FriendlyARM NanoPi R2S
#   ImmortalWrt 25.12.1
#
# 职责：
#   1. 注入 YAIF 自定义 files/
#   2. 编译阶段生成 Clashoo APK repository 配置
#   3. 编译阶段下载 Clashoo APK signing key
#
# 注意：
#   本脚本不修改 .config。
#   本脚本不负责安装 Feeds。
#   本脚本不负责选择软件包。
#   本脚本不负责执行 apk update。
#
# Clashoo：
#   - 源码由 Diy-Part1.sh 引入
#   - APK 软件源在编译阶段动态写入
#   - APK signing key 在编译阶段动态下载
# =========================================================

set -euo pipefail

echo "==> [Diy-Part2] 开始执行 R2S 编译前预处理..."

# =========================================================
# 1. 注入自定义 files
# =========================================================

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

# =========================================================
# 2. Clashoo APK Repository
# =========================================================
#
# 固定构建目标：
#   ImmortalWrt 25.12
#   NanoPi R2S
#   aarch64_generic
#
# APK-tools v3：
#   repository 直接指向 packages.adb。
#
# 不使用运行时安装脚本中的：
#   - SDK 自动判断
#   - 架构自动判断
#   - opkg 兼容
#   - feed fallback
#   - apk update
#
# =========================================================

CLASHOO_FEED_URL="https://down.dllkids.xyz/openwrt-feed/25.12/aarch64_generic/packages.adb"

CLASHOO_FEED_DIR="./files/etc/apk/repositories.d"
CLASHOO_FEED_FILE="${CLASHOO_FEED_DIR}/customfeeds.list"

echo "==> 准备 Clashoo APK repository..."

mkdir -p "$CLASHOO_FEED_DIR"

cat > "$CLASHOO_FEED_FILE" <<EOF
${CLASHOO_FEED_URL}
EOF

echo "OK：Clashoo APK repository 已生成。"
echo "    ${CLASHOO_FEED_URL}"

# =========================================================
# 3. Clashoo APK Signing Key
# =========================================================
#
# 不将第三方 signing key 提交到 YAIF Git 仓库。
#
# 每次编译时从 Clashoo 使用的 dllkids APK feed 下载当前公钥。
#
# =========================================================

CLASHOO_KEY_URL="https://down.dllkids.xyz/openwrt-feed/keys/dllkids-feed.pub.pem"

CLASHOO_KEY_DIR="./files/etc/apk/keys"
CLASHOO_KEY_FILE="${CLASHOO_KEY_DIR}/dllkids-feed.pub.pem"

echo "==> 下载 Clashoo APK signing key..."

mkdir -p "$CLASHOO_KEY_DIR"

if command -v curl >/dev/null 2>&1; then
    curl -fsSL \
        "$CLASHOO_KEY_URL" \
        -o "$CLASHOO_KEY_FILE"
elif command -v wget >/dev/null 2>&1; then
    wget -q \
        -O "$CLASHOO_KEY_FILE" \
        "$CLASHOO_KEY_URL"
else
    echo "ERROR：未找到 curl 或 wget，无法下载 Clashoo APK signing key。" >&2
    exit 1
fi

# 确保 key 文件存在且非空。
if [ ! -s "$CLASHOO_KEY_FILE" ]; then
    echo "ERROR：Clashoo APK signing key 下载失败或文件为空。" >&2
    exit 1
fi

chmod 644 "$CLASHOO_KEY_FILE"

echo "OK：Clashoo APK signing key 已准备。"
echo "    ${CLASHOO_KEY_FILE}"

# =========================================================
# 4. APK Repository / Key 最终检查
# =========================================================

echo "==> 检查 APK repository..."

if [ -s "$CLASHOO_FEED_FILE" ]; then
    echo "OK：${CLASHOO_FEED_FILE}"
else
    echo "ERROR：Clashoo APK repository 配置为空。" >&2
    exit 1
fi

echo "==> 检查 APK signing key..."

if [ -s "$CLASHOO_KEY_FILE" ]; then
    echo "OK：${CLASHOO_KEY_FILE}"
else
    echo "ERROR：Clashoo APK signing key 不存在。" >&2
    exit 1
fi

echo "==> [Diy-Part2] 编译前预处理完成。"