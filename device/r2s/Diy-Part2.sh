#!/bin/bash

echo "==> [Diy-Part2] 开始执行 R2S 编译前预处理..."

# ---------------------------------------------------------
# 1. 注入 files
# ---------------------------------------------------------

if [ -d "../files" ] && [ "$(ls -A ../files 2>/dev/null)" ]; then

    echo "==> 检测到自定义 files，正在注入..."

    mkdir -p ./files

    cp -rf ../files/. ./files/

    chmod +x ./files/etc/uci-defaults/* 2>/dev/null || true

else

    echo "==> 未发现自定义 files"

fi


# ---------------------------------------------------------
# 2. 检查 APK 配置是否存在
# ---------------------------------------------------------

echo "==> 检查 uci-defaults 补丁..."

if [ -f "./files/etc/uci-defaults/99-fix-apk-repositories" ]; then
    echo "OK: APK repository fix uci-default exists"
else
    echo "WARNING: APK repository fix missing"
fi

echo "==> 检查 APK 预置文件..."

if [ -f "./files/etc/apk/repositories.d/customfeeds.list" ]; then
    echo "OK: APK repository 已预置"
else
    echo "WARNING: 未发现 APK repository"
fi


if [ -d "./files/etc/apk/keys" ]; then
    echo "OK: APK keys 目录存在"
else
    echo "WARNING: 未发现 APK keys"
fi


# ---------------------------------------------------------
# 3. 清理垃圾文件
# ---------------------------------------------------------

echo "==> 清理 .orig / .rej"

find ./ -name "*.orig" -exec rm -f {} +
find ./ -name "*.rej" -exec rm -f {} +


echo "==> [Diy-Part2] 完成"