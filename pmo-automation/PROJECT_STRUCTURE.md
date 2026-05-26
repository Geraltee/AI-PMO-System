# PMO 自动化管理系统 - 项目结构

```
pmo-automation/
│
├── 📄 Main.ps1                    # 主入口脚本
├── 📄 README.md                   # 项目说明
├── 📄 PROJECT_STRUCTURE.md        # 本文件
│
├── 📁 config/                     # 配置文件
│   ├── settings.json              # 系统配置
│   └── cron-jobs.json             # OpenClaw Cron 任务配置
│
├── 📁 modules/                    # 功能模块
│   ├── DocumentParser.ps1         # 文档解析模块
│   ├── DashboardGenerator.ps1     # Dashboard 生成器
│   ├── RoleAssignment.ps1         # 角色分配引擎
│   ├── WBSDecomposition.ps1       # WBS 分解模块
│   ├── SOPGenerator.ps1           # SOP 生成器
│   ├── TimelineTracker.ps1        # 时间节点追踪
│   ├── WeeklySummary.ps1          # 周会总结 Bot
│   └── EmailNotifier.ps1          # 邮件提醒系统
│
├── 📁 templates/                  # 模板文件
│   ├── dashboard.html             # Dashboard HTML 模板
│   ├── email-template.html        # 邮件模板
│   └── report-template.html       # 报告模板
│
├── 📁 data/                       # 数据文件
│   ├── employees.json             # 员工信息
│   ├── employees.template.json    # 员工模板
│   ├── projects.json              # 项目数据
│   ├── projects.template.json     # 项目模板
│   ├── tasks.json                 # 任务数据
│   ├── role-assignments.json      # 角色分配结果
│   ├── milestones.json            # 里程碑数据
│   └── timeline-tracking.json     # 时间追踪数据
│
├── 📁 output/                     # 输出文件
│   ├── dashboards/                # 生成的 Dashboard
│   │   └── index.html             # 最新 Dashboard
│   ├── reports/                   # 生成的报告
│   │   ├── wbs-report-*.md        # WBS 报告
│   │   └── weekly-summary-*       # 周会总结
│   ├── sops/                      # SOP 文档
│   │   ├── sop-index.html         # SOP 索引
│   │   └── *-SOP-*.md             # SOP 文档
│   └── email-log.json             # 邮件发送日志
│
└── 📁 docs/                       # 文档
    └── usage.md                   # 使用文档
```

## 模块说明

### 1. DocumentParser.ps1 - 文档解析模块
- **功能**: 解析员工信息、项目背景等文档
- **输入**: Excel/CSV/JSON/TXT 文档
- **输出**: 结构化的 JSON 数据
- **关键函数**: 
  - `Parse-EmployeeDocument` - 解析员工文档
  - `Parse-ProjectDocument` - 解析项目文档
  - `Import-ProjectDocuments` - 批量导入

### 2. DashboardGenerator.ps1 - Dashboard 生成器
- **功能**: 生成 HTML 可视化 Dashboard
- **特性**: 
  - 项目进度展示
  - 资源分配图表 (Chart.js)
  - 时间节点甘特图
  - 实时数据统计
- **输出**: HTML Dashboard (output/dashboards/)

### 3. RoleAssignment.ps1 - 角色分配引擎
- **功能**: 根据技能匹配自动分配项目角色
- **预定义角色**:
  - ProjectManager (项目经理)
  - TechLead (技术负责人)
  - Developer (开发工程师)
  - Designer (设计师)
  - Tester (测试工程师)
  - BusinessAnalyst (业务分析师)
- **算法**: 技能匹配度计算 (0-100%)

### 4. WBSDecomposition.ps1 - WBS 分解模块
- **功能**: 自动进行项目工作分解
- **预定义模板**:
  - Software (软件开发)
  - Marketing (市场营销)
  - Event (活动组织)
  - General (通用项目)
- **输出**: 任务层级结构、WBS 报告

### 5. SOPGenerator.ps1 - SOP 生成器
- **功能**: 生成标准操作流程文档
- **预定义 SOP**:
  - 项目启动流程
  - 变更管理流程
  - 质量控制流程
  - 风险管理流程
- **输出**: Markdown + HTML 格式

### 6. TimelineTracker.ps1 - 时间节点追踪
- **功能**: 设置和追踪项目时间节点
- **特性**:
  - 逾期预警
  - 即将到期提醒
  - 里程碑管理
  - 进度计算
- **输出**: 追踪报告、警报列表

### 7. WeeklySummary.ps1 - 周会总结 Bot
- **功能**: 自动收集周报、生成会议纪要
- **特性**:
  - 任务完成统计
  - 项目进展汇总
  - 行动项生成
  - 风险提示
- **输出**: Markdown + HTML 周报

### 8. EmailNotifier.ps1 - 邮件提醒系统
- **功能**: 发送项目提醒通知
- **提醒类型**:
  - 逾期提醒
  - 即将到期提醒
  - 项目启动通知
  - 状态更新通知
- **集成**: OpenClaw message 工具

## OpenClaw 集成

### Cron 定时任务
```json
{
  "pmo-daily-check": "每天 9:00 - 项目进度检查",
  "pmo-weekly-summary": "周一 8:00 - 周会总结生成",
  "pmo-daily-reminders": "每天 17:00 - 到期提醒发送",
  "pmo-dashboard-refresh": "每 6 小时 - Dashboard 刷新"
}
```

### Message 工具集成
- 邮件提醒通过 OpenClaw message 工具发送
- 支持配置多个通知渠道
- 发送日志记录到 `output/email-log.json`

## 快速命令参考

```powershell
# 初始化
.\Main.ps1 -Action Init

# 导入文档
.\Main.ps1 -Action Import -Path "文档路径"

# 生成 WBS
.\Main.ps1 -Action Generate-WBS

# 分配角色
.\Main.ps1 -Action Assign-Roles

# 生成 Dashboard
.\Main.ps1 -Action Generate-Dashboard

# 生成 SOP
.\Main.ps1 -Action Generate-SOP

# 时间追踪
.\Main.ps1 -Action Track-Timeline

# 周会总结
.\Main.ps1 -Action Weekly-Summary

# 发送提醒
.\Main.ps1 -Action Send-Reminders

# 查看状态
.\Main.ps1 -Action Status
```

## 下一步

系统框架已创建完成，等待用户输入以下内容以填充数据：

1. **员工信息文档** - 团队成员名单、技能、可用时间
2. **项目背景文档** - 项目目标、范围、约束条件
3. **项目需求文档** - 功能需求、交付物清单

导入文档后，系统将自动：
- 解析并结构化存储数据
- 生成 WBS 分解
- 分配项目角色
- 创建 Dashboard
- 生成 SOP 文档
- 设置时间节点追踪
