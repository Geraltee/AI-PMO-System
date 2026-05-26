# PMO 自动化管理系统

## 系统架构

```
pmo-automation/
├── Main.ps1              # 主入口脚本
├── config/
│   ├── settings.json     # 系统配置
│   └── cron-jobs.json    # Cron 任务配置
├── modules/
│   ├── DocumentParser.ps1    # 文档解析模块
│   ├── DashboardGenerator.ps1 # Dashboard 生成器
│   ├── RoleAssignment.ps1    # 角色分配引擎
│   ├── WBSDecomposition.ps1  # WBS 分解模块
│   ├── SOPGenerator.ps1      # SOP 生成器
│   ├── TimelineTracker.ps1   # 时间节点追踪
│   ├── WeeklySummary.ps1     # 周会总结 Bot
│   └── EmailNotifier.ps1     # 邮件提醒系统
├── templates/
│   ├── dashboard.html    # Dashboard HTML 模板
│   ├── email-template.html # 邮件模板
│   └── report-template.html # 报告模板
├── data/
│   ├── employees.json    # 员工信息
│   ├── projects.json     # 项目数据
│   └── tasks.json        # 任务数据
├── output/
│   ├── dashboards/       # 生成的 Dashboard
│   ├── reports/          # 生成的报告
│   └── sops/             # 生成的 SOP
└── docs/
    └── usage.md          # 使用文档
```

## 功能模块

### 1. 文档解析模块 (DocumentParser.ps1)
- 解析员工信息文档
- 解析项目背景文档
- 提取关键数据结构化存储

### 2. Dashboard 生成器 (DashboardGenerator.ps1)
- 生成 HTML 可视化 Dashboard
- 项目进度展示
- 资源分配图表
- 时间节点甘特图

### 3. 自动角色分配引擎 (RoleAssignment.ps1)
- 根据技能匹配角色
- 工作量平衡算法
- 角色冲突检测

### 4. 项目分段/WBS 分解 (WBSDecomposition.ps1)
- 自动 WBS 分解
- 任务层级生成
- 依赖关系建立

### 5. SOP 生成器 (SOPGenerator.ps1)
- 标准操作流程生成
- 模板化文档输出
- 版本管理

### 6. 时间节点设置与追踪 (TimelineTracker.ps1)
- 里程碑设置
- 进度追踪
- 延期预警

### 7. 周会总结 Bot (WeeklySummary.ps1)
- 自动收集周报
- 生成会议纪要
- 行动项追踪

### 8. 邮件提醒系统 (EmailNotifier.ps1)
- 到期提醒
- 项目启动通知
- 状态更新通知

## 快速开始

```powershell
# 初始化系统
.\Main.ps1 -Action Init

# 导入项目文档
.\Main.ps1 -Action Import -Path "项目文档路径"

# 生成 Dashboard
.\Main.ps1 -Action Generate-Dashboard

# 查看帮助
.\Main.ps1 -Help
```

## OpenClaw 集成

系统已配置 OpenClaw cron 任务：
- 每日 9:00 - 项目进度检查
- 每周一 8:00 - 周会总结生成
- 每日 17:00 - 到期提醒发送

## 数据输入格式

等待用户输入以下文档内容：
1. 员工信息表（姓名、技能、可用时间）
2. 项目背景文档（目标、范围、约束）
3. 项目需求文档（功能、交付物）
