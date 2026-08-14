# 特性

- 基于原生 ImmortalWrt 25.12 编译，默认管理地址 192.168.1.1
- 适配 RK3328 硬件（NanoPi R2S），内置内核驱动与固件

## 项目结构

YAIF-25.12/
├── .github/
│   └── workflows/
│       ├── build-r2s.yml             # 整合后的核心编译工作流 (支持选项触发 SSH)
│       └── clean-runs.yml            # 自动清理历史 Workflow runs 记录
├── device/
│   └── r2s/
│       ├── config.seed               # 编译种子配置文件
│       ├── Diy-Part1.sh              # 编译前：添加自定义 Feeds / 软件源
│       └── Diy-Part2.sh              # 编译前：修改默认配置、网卡、防火墙、版本号等
├── files/                            # 替换 PATCH/files，更符合 OpenWrt 原生规范
│   └── etc/
│       ├── apk/
│       │   └── keys/                 # 25.12 APK 验签公钥
│       └── config/
│           └── network               # 预设网络配置
├── LICENSE
└── README.md
