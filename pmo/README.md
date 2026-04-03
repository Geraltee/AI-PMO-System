# AI PMO 原型系统

基于 OpenClaw 构建的项目管理办公室 AI 助手

## 核心功能

- 📋 项目状态跟踪
- ⚠️ 风险预警
- 📅 里程碑提醒
- 👥 资源协调
- 📊 周报自动生成

## 文件结构

```
pmo/
├── README.md           # 本文件
├── projects/           # 项目档案
│   └── [project-id].md
├── memory/             # PMO 记忆库
│   └── pmo-memory.md
├── templates/          # 模板文件
│   ├── project-template.md
│   ├── weekly-report.md
│   └── risk-log.md
└── config/             # 配置
    └── cron-jobs.json
```

## 快速开始

1. 创建新项目：`openclaw pmo new [项目名]`
2. 查看项目状态：`openclaw pmo status`
3. 生成周报：`openclaw pmo report`

## 当前状态

🟡 原型开发中
