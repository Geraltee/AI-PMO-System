# AI-PMO-System 私有化部署指南

> **版本**: 1.0  
> **适用环境**: Windows Server 2016/2019/2022 · 内网私有化  
> **预计部署时间**: 30 分钟

---

## 目录

1. [系统要求](#1-系统要求)
2. [快速部署（5分钟）](#2-快速部署5分钟)
3. [完整内网部署](#3-完整内网部署)
4. [Active Directory 集成](#4-active-directory-集成)
5. [Microsoft 365 接入](#5-microsoft-365-接入)
6. [定时任务配置（OpenClaw Cron）](#6-定时任务配置openclaw-cron)
7. [通知渠道配置](#7-通知渠道配置)
8. [安全加固](#8-安全加固)
9. [故障排查](#9-故障排查)

---

## 1. 系统要求

| 组件 | 最低要求 | 推荐 |
|------|----------|------|
| 操作系统 | Windows Server 2016 | Windows Server 2022 |
| PowerShell | 5.1 | 7.4+ |
| 内存 | 2 GB | 4 GB |
| 磁盘 | 10 GB | 50 GB |
| .NET Framework | 4.7.2 | 4.8 |
| Node.js | 16 LTS | 20 LTS（用于 Web 服务器） |
| OpenClaw | 最新版 | 最新版（用于 Cron 任务） |

**网络要求**：
- 如需 Microsoft Graph API：内网需能访问 `https://login.microsoftonline.com` 和 `https://graph.microsoft.com`
- 如需飞书/企微/钉钉通知：内网需能访问对应 Webhook 域名
- 纯离线模式：无网络要求（通知功能不可用）

---

## 2. 快速部署（5分钟）

### 步骤 1：放置文件

将整个 `AI-PMO-System/` 目录放到服务器上，推荐路径：

```
D:\AI-PMO-System\
```

### 步骤 2：运行初始化向导

打开 PowerShell（以管理员身份），执行：

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
cd D:\AI-PMO-System\pmo-automation
.\Setup-Wizard.ps1
```

向导将引导您完成：
- ✅ 环境检测
- ✅ 组织信息配置
- ✅ 通知渠道配置
- ✅ 初始数据生成

### 步骤 3：启动 Dashboard Web 服务

```powershell
cd D:\AI-PMO-System\pmo-automation\output\dashboard-with-retrieval
npx serve . --listen 5000
```

访问：**http://localhost:5000**（或局域网 IP `http://<服务器IP>:5000`）

---

## 3. 完整内网部署

### 3.1 目录结构部署

```
D:\AI-PMO-System\
├── pmo-automation\        ← PowerShell 核心引擎
│   ├── Main.ps1
│   ├── Setup-Wizard.ps1
│   ├── config\
│   │   ├── settings.json         ← 主配置
│   │   ├── email-config.json     ← 邮件配置
│   │   └── notification-config.json ← 通知配置
│   ├── modules\
│   ├── data\
│   │   ├── employees.json        ← 员工数据（需填充）
│   │   └── projects.json         ← 项目数据（需填充）
│   └── output\
│       └── dashboard-with-retrieval\ ← Dashboard Web 文件
└── pmo\                   ← Web 服务器配置
    └── web\
        └── start-server.ps1
```

### 3.2 配置服务器自动启动

创建 Windows 计划任务，开机自动启动 Dashboard：

```powershell
# 创建开机启动任务
$action  = New-ScheduledTaskAction -Execute "node" -Argument "-e `"require('child_process').spawn('npx',['serve','.','-l','5000'],{cwd:'D:\\AI-PMO-System\\pmo-automation\\output\\dashboard-with-retrieval',stdio:'inherit',shell:true})`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "PMO-Dashboard-Server" -Settings $settings -RunLevel Highest -Force
```

### 3.3 配置防火墙（允许局域网访问）

```powershell
New-NetFirewallRule -DisplayName "PMO Dashboard" -Direction Inbound -Port 5000 -Protocol TCP -Action Allow
```

### 3.4 自定义端口与域名（可选）

修改 `pmo-automation/config/settings.json`：

```json
{
  "organization": {
    "dashboardUrl": "http://pmo.yourcompany.com"
  },
  "server": {
    "port": 80,
    "host": "0.0.0.0"
  }
}
```

---

## 4. Active Directory 集成

> 用于自动从 AD 同步员工信息，无需手动维护 `employees.json`

### 4.1 安装 AD 模块

```powershell
# Windows Server 内置
Import-Module ActiveDirectory

# 测试连接
Get-ADUser -Filter * -Properties DisplayName, Mail, Department | Select-Object -First 5
```

### 4.2 同步脚本

在 `pmo-automation/modules/` 下创建 `ADSync.ps1`：

```powershell
# ADSync.ps1 - 从 AD 同步员工数据
param(
    [string]$OUPath = "OU=员工,DC=yourcompany,DC=com",
    [string]$Filter = "Enabled -eq 'True'"
)

Import-Module ActiveDirectory

$adUsers = Get-ADUser -Filter $Filter -SearchBase $OUPath `
    -Properties DisplayName, Mail, Department, Title, Manager, Enabled

$employees = $adUsers | ForEach-Object {
    @{
        id        = "EMP-" + $_.SamAccountName.ToUpper()
        name      = $_.DisplayName
        email     = $_.Mail
        adAccount = $_.SamAccountName
        department = $_.Department
        title     = $_.Title
        role      = Map-ADTitleToRole $_.Title
        workload  = 0
        available = $_.Enabled
    }
}

$employees | ConvertTo-Json -Depth 5 | `
    Set-Content "D:\AI-PMO-System\pmo-automation\data\employees.json" -Encoding UTF8

Write-Host "✅ 已同步 $($employees.Count) 名员工"

function Map-ADTitleToRole($title) {
    if ($title -match "项目经理|PM")  { return "ProjectManager" }
    if ($title -match "架构师|技术总监") { return "TechLead" }
    if ($title -match "测试")          { return "Tester" }
    if ($title -match "设计")          { return "Designer" }
    if ($title -match "分析师|BA")     { return "BusinessAnalyst" }
    return "Developer"
}
```

### 4.3 定时同步

每日凌晨 2 点自动同步：

```powershell
$trigger = New-ScheduledTaskTrigger -Daily -At 02:00
$action  = New-ScheduledTaskAction -Execute "powershell" -Argument "-ExecutionPolicy Bypass -File D:\AI-PMO-System\pmo-automation\modules\ADSync.ps1"
Register-ScheduledTask -TaskName "PMO-AD-Sync" -Action $action -Trigger $trigger -RunLevel Highest -Force
```

---

## 5. Microsoft 365 接入

> 用于真实 OneDrive 文档检索（替换演示数据）

### 5.1 注册 Azure AD 应用

1. 登录 [portal.azure.com](https://portal.azure.com)
2. **Azure Active Directory** → **应用注册** → **新建注册**
3. 名称：`AI-PMO-System`
4. 支持账户类型：`仅此组织目录中的账户`
5. 重定向 URI → **单页应用程序(SPA)**：
   ```
   http://localhost:5000/dashboard-with-retrieval/documents.html
   http://pmo.yourcompany.com/documents.html
   ```
6. 注册后记录 **应用程序(客户端) ID**

### 5.2 配置 API 权限

在应用的 **API 权限** 页面，添加：
- `Microsoft Graph` → **委托的权限**:
  - `Files.Read.All` (OneDrive 文档检索)
  - `User.Read` (用户信息)
  
点击"代表组织授予管理员同意"（需管理员账户）。

### 5.3 在 Dashboard 中启用

打开 `http://localhost:5000/documents.html`，点击**连接 OneDrive**，输入 Client ID，完成 OAuth 登录。

Client ID 会保存在浏览器 localStorage，下次自动使用。

---

## 6. 定时任务配置（OpenClaw Cron）

### 6.1 导入 Cron 任务

```bash
# 在 OpenClaw 中执行
openclaw cron import D:\AI-PMO-System\pmo-automation\config\cron-jobs.json
```

### 6.2 Cron 任务说明

| 任务名 | 执行时间 | 功能 |
|--------|----------|------|
| `dashboard-refresh` | 每天 08:00 | 刷新 Dashboard 数据 |
| `weekly-summary` | 每周五 17:00 | 生成周报 |
| `task-reminder` | 每天 09:00 | 发送任务提醒 |
| `risk-check` | 每天 10:00 | 风险预警检测 |
| `ad-sync` | 每天 02:00 | AD 员工数据同步 |

### 6.3 修复时区（重要！）

编辑 `config/cron-jobs.json`，将所有时区改为 `Asia/Shanghai`：

```json
{
  "jobs": [
    {
      "name": "dashboard-refresh",
      "schedule": "0 8 * * *",
      "timezone": "Asia/Shanghai",
      "command": "powershell -ExecutionPolicy Bypass -File D:\\AI-PMO-System\\pmo-automation\\Main.ps1 -Action Dashboard"
    }
  ]
}
```

---

## 7. 通知渠道配置

### 7.1 邮件（SMTP）

适用于 Microsoft 365 / Exchange / 企业邮箱：

```json
// config/email-config.json
{
  "host":     "smtp.office365.com",
  "port":     587,
  "username": "pmo-noreply@yourcompany.com",
  "password": "<应用密码>",
  "ssl":      true
}
```

**获取 Office 365 应用密码**：
`Microsoft 账户` → `安全信息` → `其他安全验证` → `应用密码` → `创建`

### 7.2 飞书 Webhook

```json
// config/notification-config.json
{
  "enabled": ["feishu"],
  "feishu": {
    "webhook": "https://open.feishu.cn/open-apis/bot/v2/hook/xxxxxxxx",
    "secret": ""
  }
}
```

测试：
```powershell
.\modules\feishu-webhook.ps1 -Message "PMO 系统通知测试 ✅"
```

### 7.3 企业微信机器人

```json
"wxwork": {
  "webhook": "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxxxxxxx"
}
```

### 7.4 钉钉机器人

```json
"dingtalk": {
  "webhook": "https://oapi.dingtalk.com/robot/send?access_token=xxxxxxxx",
  "secret": "<加签密钥>"
}
```

---

## 8. 安全加固

### 8.1 配置文件权限

```powershell
# 限制配置文件只有服务账户可读
$acl = Get-Acl "D:\AI-PMO-System\pmo-automation\config\email-config.json"
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "BUILTIN\Administrators", "FullControl", "Allow")
$acl.AddAccessRule($rule)
Set-Acl "D:\AI-PMO-System\pmo-automation\config\email-config.json" $acl
```

### 8.2 使用 Windows 凭据管理器存储密码（推荐）

```powershell
# 存储 SMTP 密码（比明文更安全）
$cred = Get-Credential -Message "输入 SMTP 账户凭据"
$cred | Export-Clixml "D:\AI-PMO-System\pmo-automation\config\.smtp-cred.xml"
```

在 `EmailNotifier.ps1` 中加载：
```powershell
$cred = Import-Clixml ".\config\.smtp-cred.xml"
```

### 8.3 Dashboard 访问控制（IIS 反代）

如需加入 Windows 集成认证，通过 IIS 反向代理 Dashboard：

```xml
<!-- web.config 示例 -->
<authentication>
  <windowsAuthentication enabled="true" />
  <anonymousAuthentication enabled="false" />
</authentication>
```

---

## 9. 故障排查

### Q1: PowerShell 提示"此系统上禁止运行脚本"

```powershell
# 仅对当前进程放开（不影响全局安全策略）
Set-ExecutionPolicy Bypass -Scope Process -Force
```

### Q2: Dashboard 样式错乱或页面空白

- 确认用 Web 服务器（`npx serve`）访问，而不是直接双击 HTML 文件
- 检查 Chart.js CDN 是否可访问（内网离线时需本地化）

### Q3: Graph API 登录失败 "AADSTS50011"

重定向 URI 不匹配。检查 Azure AD 应用注册中的重定向 URI 是否与实际访问地址完全一致（包括端口）。

### Q4: 飞书 Webhook 报错 "sign check failed"

检查 `notification-config.json` 中的 `secret` 字段是否与飞书机器人配置的加签密钥一致。

### Q5: 邮件发送失败 "535 Authentication unsuccessful"

Office 365 要求使用应用密码，而不是账号登录密码。
- 管理员需在 M365 管理中心启用"基本身份验证"（SMTP AUTH）
- 或改用"应用密码"

### Q6: 员工/项目数据为空

运行初始化：
```powershell
.\Main.ps1 -Action Init
```
然后编辑 `data/employees.json` 和 `data/projects.json`，填入真实数据后运行：
```powershell
.\Main.ps1 -Action Dashboard
```

---

## 附录：常用命令速查

```powershell
# 初始化系统
.\Main.ps1 -Action Init

# 生成 Dashboard
.\Main.ps1 -Action Dashboard

# 生成周报
.\Main.ps1 -Action WeeklySummary

# 检查逾期任务
.\Main.ps1 -Action TimelineCheck

# 发送邮件提醒
.\Main.ps1 -Action SendReminder

# 运行初始化向导
.\Setup-Wizard.ps1

# 重置所有配置
.\Setup-Wizard.ps1 -Reset

# 启动 Dashboard Web 服务
cd output\dashboard-with-retrieval && npx serve . --listen 5000
```

---

*文档更新：2026-05-15 | AI-PMO-System v2.0*
