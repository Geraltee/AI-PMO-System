# ============================================================
# AI-PMO-System Setup Wizard
# 一键初始化向导 - 引导式5分钟完成首次配置
# ============================================================

param(
    [switch]$Silent,   # 静默模式（跳过确认）
    [switch]$Reset     # 重置所有配置
)

$VERSION = "1.0.0"
$BASE_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║           AI-PMO-System  Setup Wizard v$VERSION              ║" -ForegroundColor Cyan
    Write-Host "  ║          私有化 PMO 智能管理平台 · 初始化向导             ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([int]$Step, [int]$Total, [string]$Title)
    Write-Host ""
    Write-Host "  ─────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  步骤 $Step/$Total ▶  $Title" -ForegroundColor Yellow
    Write-Host "  ─────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
}

function Write-Success {
    param([string]$Msg)
    Write-Host "  ✅  $Msg" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Msg)
    Write-Host "  ⚠️   $Msg" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Msg)
    Write-Host "  ℹ️   $Msg" -ForegroundColor Cyan
}

function Write-Error2 {
    param([string]$Msg)
    Write-Host "  ❌  $Msg" -ForegroundColor Red
}

function Ask-Input {
    param([string]$Prompt, [string]$Default = "")
    if ($Default) {
        $hint = " [默认: $Default]"
    } else {
        $hint = ""
    }
    $val = Read-Host "  $Prompt$hint"
    if ([string]::IsNullOrWhiteSpace($val) -and $Default) {
        return $Default
    }
    return $val
}

function Ask-YesNo {
    param([string]$Prompt, [bool]$DefaultYes = $true)
    $hint = if ($DefaultYes) { "[Y/n]" } else { "[y/N]" }
    $val = Read-Host "  $Prompt $hint"
    if ([string]::IsNullOrWhiteSpace($val)) { return $DefaultYes }
    return ($val.ToLower() -eq "y" -or $val.ToLower() -eq "yes" -or $val.ToLower() -eq "是")
}

# ─────────────────────────────────────────
# 步骤 1: 检测环境
# ─────────────────────────────────────────
function Step-CheckEnvironment {
    Write-Step 1 5 "检测运行环境"
    
    $issues = @()

    # 检查 PowerShell 版本
    $psVersion = $PSVersionTable.PSVersion.Major
    if ($psVersion -ge 5) {
        Write-Success "PowerShell $($PSVersionTable.PSVersion) ✓"
    } else {
        Write-Warn "PowerShell 版本 $($PSVersionTable.PSVersion) 低于推荐版本 5.1"
        $issues += "PowerShell 版本过低"
    }

    # 检查 Node.js (用于本地 HTTP 服务器)
    $nodeVersion = node --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Node.js $nodeVersion ✓"
    } else {
        Write-Warn "未检测到 Node.js，Dashboard Web 服务需要 Node.js"
        Write-Info "安装: https://nodejs.org/  (推荐 LTS 版本)"
        $issues += "Node.js 未安装"
    }

    # 检查目录结构
    $requiredDirs = @("modules", "config", "data", "output", "templates")
    foreach ($dir in $requiredDirs) {
        $fullPath = Join-Path $BASE_DIR $dir
        if (Test-Path $fullPath) {
            Write-Success "目录 $dir ✓"
        } else {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-Info "已创建目录: $dir"
        }
    }

    if ($issues.Count -gt 0) {
        Write-Host ""
        Write-Warn "发现 $($issues.Count) 个警告，建议解决后再继续"
        if (-not $Silent) {
            $continue = Ask-YesNo "是否继续配置？"
            if (-not $continue) { exit 1 }
        }
    } else {
        Write-Success "环境检测通过！"
    }
}

# ─────────────────────────────────────────
# 步骤 2: 组织信息配置
# ─────────────────────────────────────────
function Step-OrgConfig {
    Write-Step 2 5 "配置组织信息"
    
    Write-Info "这些信息将显示在 Dashboard 顶部"
    Write-Host ""
    
    $orgName      = Ask-Input "公司/组织名称" "我的公司"
    $pmoName      = Ask-Input "PMO 部门名称" "项目管理办公室"
    $adminName    = Ask-Input "管理员姓名"   "PMO 管理员"
    $adminEmail   = Ask-Input "管理员邮箱"   "pmo@company.com"
    $timezone     = Ask-Input "时区"          "Asia/Shanghai"
    $dashboardUrl = Ask-Input "Dashboard 访问地址" "http://localhost:5000"

    $settingsPath = Join-Path $BASE_DIR "config\settings.json"
    
    # 读取现有配置或创建新配置
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    } else {
        $settings = [PSCustomObject]@{}
    }

    # 更新组织配置
    if (-not $settings.PSObject.Properties["organization"]) {
        $settings | Add-Member -MemberType NoteProperty -Name "organization" -Value ([PSCustomObject]@{})
    }
    $settings.organization = [PSCustomObject]@{
        name       = $orgName
        pmoName    = $pmoName
        adminName  = $adminName
        adminEmail = $adminEmail
        timezone   = $timezone
        dashboardUrl = $dashboardUrl
    }

    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Write-Success "组织信息已保存到 config/settings.json"
}

# ─────────────────────────────────────────
# 步骤 3: 通知渠道配置
# ─────────────────────────────────────────
function Step-NotificationConfig {
    Write-Step 3 5 "配置通知渠道"
    
    Write-Info "选择你需要启用的通知方式（可多选）"
    Write-Host ""

    $notifConfig = [PSCustomObject]@{
        enabled  = @()
        email    = $null
        feishu   = $null
        wxwork   = $null
        dingtalk = $null
    }

    # ── 邮件 ──────────────────────────────
    $enableEmail = Ask-YesNo "启用 邮件通知 (SMTP)？" $false
    if ($enableEmail) {
        $smtpHost = Ask-Input "SMTP 服务器" "smtp.office365.com"
        $smtpPort = Ask-Input "SMTP 端口" "587"
        $smtpUser = Ask-Input "SMTP 用户名（邮箱地址）"
        $smtpPass = Read-Host "  SMTP 密码（应用密码）" -AsSecureString
        $smtpPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($smtpPass))
        
        $notifConfig.email = [PSCustomObject]@{
            host     = $smtpHost
            port     = [int]$smtpPort
            username = $smtpUser
            password = $smtpPassPlain
            ssl      = $true
        }
        $notifConfig.enabled += "email"
        
        # 保存到 email-config.json
        $emailConfigPath = Join-Path $BASE_DIR "config\email-config.json"
        $notifConfig.email | ConvertTo-Json | Set-Content $emailConfigPath -Encoding UTF8
        Write-Success "邮件配置已保存（config/email-config.json）"
    }

    # ── 飞书 ──────────────────────────────
    $enableFeishu = Ask-YesNo "启用 飞书 Webhook 通知？" $false
    if ($enableFeishu) {
        Write-Info "飞书群机器人 Webhook URL 获取方式："
        Write-Info "  飞书群 → 群设置 → 群机器人 → 添加机器人 → 自定义机器人 → 复制 Webhook"
        $feishuWebhook = Ask-Input "飞书 Webhook URL"
        $feishuSecret  = Ask-Input "飞书签名密钥（选填，不填则留空）" ""
        
        $notifConfig.feishu = [PSCustomObject]@{
            webhook = $feishuWebhook
            secret  = $feishuSecret
        }
        $notifConfig.enabled += "feishu"
        Write-Success "飞书 Webhook 已配置"
    }

    # ── 企业微信 ──────────────────────────
    $enableWxWork = Ask-YesNo "启用 企业微信机器人 通知？" $false
    if ($enableWxWork) {
        Write-Info "企业微信群机器人：群 → 群机器人 → 添加 → 复制 Webhook"
        $wxWebhook = Ask-Input "企业微信 Webhook URL"
        $notifConfig.wxwork = [PSCustomObject]@{ webhook = $wxWebhook }
        $notifConfig.enabled += "wxwork"
        Write-Success "企业微信机器人已配置"
    }

    # ── 钉钉 ──────────────────────────────
    $enableDingTalk = Ask-YesNo "启用 钉钉机器人 通知？" $false
    if ($enableDingTalk) {
        Write-Info "钉钉群机器人：群设置 → 智能群助手 → 添加机器人 → 自定义 → 复制 Webhook"
        $ddWebhook = Ask-Input "钉钉 Webhook URL"
        $ddSecret  = Ask-Input "钉钉加签密钥（选填）" ""
        $notifConfig.dingtalk = [PSCustomObject]@{
            webhook = $ddWebhook
            secret  = $ddSecret
        }
        $notifConfig.enabled += "dingtalk"
        Write-Success "钉钉机器人已配置"
    }

    # 保存通知配置
    $notifPath = Join-Path $BASE_DIR "config\notification-config.json"
    $notifConfig | ConvertTo-Json -Depth 5 | Set-Content $notifPath -Encoding UTF8
    Write-Success "通知渠道配置已保存（config/notification-config.json）"

    if ($notifConfig.enabled.Count -eq 0) {
        Write-Warn "未启用任何通知渠道，稍后可编辑 config/notification-config.json 添加"
    }
}

# ─────────────────────────────────────────
# 步骤 4: 初始化数据
# ─────────────────────────────────────────
function Step-InitData {
    Write-Step 4 5 "初始化项目数据"

    $dataDir = Join-Path $BASE_DIR "data"

    # employees.json
    $employeesPath = Join-Path $dataDir "employees.json"
    if (-not (Test-Path $employeesPath) -or $Reset) {
        $employees = @(
            [PSCustomObject]@{
                id        = "EMP-001"
                name      = "请替换为真实姓名"
                email     = "employee1@company.com"
                role      = "ProjectManager"
                skills    = @("项目管理", "需求分析")
                workload  = 0
                available = $true
            },
            [PSCustomObject]@{
                id        = "EMP-002"
                name      = "请替换为真实姓名"
                email     = "employee2@company.com"
                role      = "TechLead"
                skills    = @("架构设计", "Java", "Python")
                workload  = 0
                available = $true
            }
        )
        $employees | ConvertTo-Json -Depth 5 | Set-Content $employeesPath -Encoding UTF8
        Write-Success "employees.json 已创建（请替换为真实员工数据）"
    } else {
        Write-Info "employees.json 已存在，跳过（使用 -Reset 强制重置）"
    }

    # projects.json
    $projectsPath = Join-Path $dataDir "projects.json"
    if (-not (Test-Path $projectsPath) -or $Reset) {
        $projects = @(
            [PSCustomObject]@{
                id        = "PRJ-$(Get-Date -Format 'yyyy')-001"
                name      = "示例项目（请修改）"
                type      = "Software"
                status    = "进行中"
                progress  = 0
                startDate = (Get-Date).ToString("yyyy-MM-dd")
                endDate   = (Get-Date).AddMonths(3).ToString("yyyy-MM-dd")
                manager   = "EMP-001"
                budget    = 0
                risks     = @()
            }
        )
        $projects | ConvertTo-Json -Depth 5 | Set-Content $projectsPath -Encoding UTF8
        Write-Success "projects.json 已创建（请替换为真实项目数据）"
    } else {
        Write-Info "projects.json 已存在，跳过"
    }

    # tasks.json
    $tasksPath = Join-Path $dataDir "tasks.json"
    if (-not (Test-Path $tasksPath) -or $Reset) {
        "[]" | Set-Content $tasksPath -Encoding UTF8
        Write-Success "tasks.json 已初始化（空任务列表）"
    }
}

# ─────────────────────────────────────────
# 步骤 5: 生成 Dashboard & 完成向导
# ─────────────────────────────────────────
function Step-Finalize {
    Write-Step 5 5 "完成配置 & 启动系统"

    # 写入初始化完成标志
    $initFlag = Join-Path $BASE_DIR "config\.initialized"
    $initInfo = [PSCustomObject]@{
        version    = $VERSION
        initTime   = (Get-Date).ToString("o")
        setupBy    = $env:USERNAME
    }
    $initInfo | ConvertTo-Json | Set-Content $initFlag -Encoding UTF8
    Write-Success "初始化标志已写入 config/.initialized"

    # 尝试生成 Dashboard
    $mainScript = Join-Path $BASE_DIR "Main.ps1"
    if (Test-Path $mainScript) {
        Write-Info "正在生成 Dashboard..."
        try {
            & $mainScript -Action Dashboard 2>&1 | Out-Null
            Write-Success "Dashboard 生成完成！"
        } catch {
            Write-Warn "Dashboard 生成跳过（稍后手动运行: .\Main.ps1 -Action Dashboard）"
        }
    }

    # 打印完成摘要
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║                  🎉  配置完成！                          ║" -ForegroundColor Green
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-Host "  ║  下一步操作：                                             ║" -ForegroundColor Green
    Write-Host "  ║                                                           ║" -ForegroundColor Green
    Write-Host "  ║  1. 编辑 data/employees.json  填入真实员工信息            ║" -ForegroundColor Green
    Write-Host "  ║  2. 编辑 data/projects.json   填入真实项目数据            ║" -ForegroundColor Green
    Write-Host "  ║  3. 运行 Dashboard:                                       ║" -ForegroundColor Green
    Write-Host "  ║     .\Main.ps1 -Action Dashboard                          ║" -ForegroundColor Green
    Write-Host "  ║  4. 启动 Web 服务器：                                     ║" -ForegroundColor Green
    Write-Host "  ║     cd output\dashboard-with-retrieval                    ║" -ForegroundColor Green
    Write-Host "  ║     npx serve .                                           ║" -ForegroundColor Green
    Write-Host "  ║                                                           ║" -ForegroundColor Green
    Write-Host "  ║  📖 详细文档：docs/DEPLOYMENT-GUIDE.md                   ║" -ForegroundColor Green
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
}

# ─────────────────────────────────────────
# 主流程
# ─────────────────────────────────────────
Write-Banner

Write-Host "  本向导将引导您完成 AI-PMO-System 的初始化配置（约 5 分钟）" -ForegroundColor White
Write-Host "  配置完成后可随时重新运行此脚本更新设置" -ForegroundColor DarkGray
Write-Host ""

if (-not $Silent) {
    $start = Ask-YesNo "开始配置向导？"
    if (-not $start) {
        Write-Host "  已取消。您可以稍后重新运行 .\Setup-Wizard.ps1" -ForegroundColor DarkGray
        exit 0
    }
}

Step-CheckEnvironment
Step-OrgConfig
Step-NotificationConfig
Step-InitData
Step-Finalize
