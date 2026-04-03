# AI PMO 系统 - 主脚本

这是 PMO 系统的核心命令脚本，用于项目管理自动化。

## 使用方法

```powershell
# 创建新项目
pmo\scripts\pmo.ps1 new "项目名称"

# 查看项目状态
pmo\scripts\pmo.ps1 status

# 查看项目详情
pmo\scripts\pmo.ps1 show PRJ-2026-001

# 生成周报
pmo\scripts\pmo.ps1 report

# 添加风险
pmo\scripts\pmo.ps1 risk-add "风险描述" --project PRJ-2026-001 --impact high --probability medium

# 更新项目状态
pmo\scripts\pmo.ps1 update PRJ-2026-001 --status yellow --note "进展说明"

# 里程碑提醒
pmo\scripts\pmo.ps1 milestones --days 7
```

## 自动化任务

以下任务可通过 cron 自动执行：

1. **每日检查** - 扫描所有项目，识别风险
2. **周报生成** - 汇总进展，生成报告
3. **里程碑提醒** - 提前通知即将到期的里程碑
4. **资源预警** - 检测资源缺口

## 集成 OpenClaw 能力

- 使用 `memory_search` 查询历史项目经验
- 使用 `cron` 设置定时提醒
- 使用 `sessions_spawn` 创建项目专属会话
- 使用 `message` 发送通知

---
*版本：0.1.0-alpha*
