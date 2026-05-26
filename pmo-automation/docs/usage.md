# PMO 自动化管理系统 - 使用文档

## 快速开始

### 1. 初始化系统

```powershell
cd C:\Users\Administrator\.openclaw\workspace\pmo-automation
.\Main.ps1 -Action Init
```

### 2. 导入项目文档

准备以下文档：
- **员工信息表**: 包含姓名、技能、部门、可用时间等
- **项目背景文档**: 包含项目目标、范围、时间、预算等
- **项目需求文档**: 包含功能需求、交付物等

文档格式支持：JSON、CSV、TXT

```powershell
.\Main.ps1 -Action Import -Path "C:\项目文档路径"
```

### 3. 生成 WBS 分解

```powershell
.\Main.ps1 -Action Generate-WBS
```

系统会自动选择适合的 WBS 模板（软件开发/市场营销/活动组织/通用）

### 4. 分配项目角色

```powershell
.\Main.ps1 -Action Assign-Roles
```

系统会根据员工技能自动匹配项目角色

### 5. 生成 Dashboard

```powershell
.\Main.ps1 -Action Generate-Dashboard
```

生成的 HTML Dashboard 位于 `output/dashboards/` 目录

### 6. 生成 SOP 文档

```powershell
.\Main.ps1 -Action Generate-SOP
```

生成的 SOP 包括：
- 项目启动流程
- 变更管理流程
- 质量控制流程
- 风险管理流程

### 7. 查看系统状态

```powershell
.\Main.ps1 -Action Status
```

## OpenClaw Cron 集成

### 启用定时任务

```powershell
# 查看当前 cron 任务
openclaw cron list

# 导入 PMO cron 配置
openclaw cron import .\config\cron-jobs.json
```

### 预配置任务

| 任务 ID | 名称 | 时间 | 说明 |
|--------|------|------|------|
| pmo-daily-check | 每日项目进度检查 | 每天 9:00 | 检查逾期和即将到期的任务 |
| pmo-weekly-summary | 周会总结生成 | 周一 8:00 | 生成周会总结报告 |
| pmo-daily-reminders | 每日提醒发送 | 每天 17:00 | 发送到期提醒 |
| pmo-dashboard-refresh | Dashboard 刷新 | 每 6 小时 | 刷新 Dashboard 数据 |

## 数据格式

### 员工信息 (employees.json)

```json
{
  "EmployeeId": "EMP001",
  "Name": "张三",
  "Department": "技术部",
  "Skills": ["项目管理", "Java", "架构设计"],
  "Availability": "全职",
  "Email": "zhangsan@company.com"
}
```

### 项目信息 (projects.json)

```json
{
  "ProjectId": "PRJ-2024-001",
  "ProjectName": "企业门户系统升级",
  "Type": "software",
  "Status": "active",
  "Priority": "high",
  "StartDate": "2024-04-01",
  "EndDate": "2024-08-31",
  "Objectives": "项目目标描述",
  "Scope": "项目范围描述",
  "RequiredRoles": ["ProjectManager", "Developer", "Tester"]
}
```

## 输出文件

| 目录 | 内容 |
|------|------|
| output/dashboards/ | HTML Dashboard |
| output/reports/ | 周报、WBS 报告 |
| output/sops/ | SOP 文档 |
| data/ | 结构化数据（员工、项目、任务） |

## 常见问题

### Q: 如何添加自定义 SOP 模板？

编辑 `modules\SOPGenerator.ps1`，在 `$SOPTemplates` 中添加新模板。

### Q: 如何修改 WBS 模板？

编辑 `modules\WBSDecomposition.ps1`，在 `$WBSTemplates` 中修改或添加模板。

### Q: 邮件提醒如何配置？

目前通过 OpenClaw message 工具发送，需要配置相应的消息通道。
编辑 `config\settings.json` 中的 `NotificationChannels` 配置。

### Q: Dashboard 不显示图表？

确保可以访问 Chart.js CDN，或下载 Chart.js 到本地。

## 技术支持

如有问题，请查看日志文件：
- `output\email-log.json` - 邮件发送日志
- `data\timeline-tracking.json` - 时间追踪数据
