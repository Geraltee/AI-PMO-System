# ============================================================
# feishu-webhook.ps1 - 飞书 Webhook 通知推送
# 用法：.\feishu-webhook.ps1 -Message "你好，PMO！"
#       .\feishu-webhook.ps1 -Type weekly -ProjectId PRJ-2026-001
# ============================================================

param(
    [string]$Message  = "",             # 直接发送文本消息
    [string]$Type     = "text",         # text | weekly | alert | card
    [string]$ProjectId = "",            # 项目 ID（用于周报）
    [string]$WebhookUrl = "",           # 临时覆盖 Webhook URL
    [switch]$Test                       # 发送测试消息
)

$BASE_DIR   = Split-Path -Parent $MyInvocation.MyCommand.Path
$CONFIG_PATH = Join-Path $BASE_DIR "config\notification-config.json"
$DATA_DIR    = Join-Path $BASE_DIR "data"

# ─────────────────────────────────────────
# 加载配置
# ─────────────────────────────────────────
function Load-Config {
    if (-not (Test-Path $CONFIG_PATH)) {
        Write-Error "找不到通知配置文件: $CONFIG_PATH`n请先运行 .\Setup-Wizard.ps1 配置飞书 Webhook"
        exit 1
    }
    $cfg = Get-Content $CONFIG_PATH -Raw | ConvertFrom-Json
    if (-not $cfg.feishu -or -not $cfg.feishu.webhook) {
        Write-Error "飞书 Webhook 未配置，请编辑 config/notification-config.json"
        exit 1
    }
    return $cfg.feishu
}

# ─────────────────────────────────────────
# 生成签名（飞书安全配置）
# ─────────────────────────────────────────
function Get-FeishuSign {
    param([string]$Secret, [long]$Timestamp)
    if (-not $Secret) { return $null }
    $content  = "$Timestamp`n$Secret"
    $hmac     = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = [System.Text.Encoding]::UTF8.GetBytes($Secret)
    $hash     = $hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($content))
    return [Convert]::ToBase64String($hash)
}

# ─────────────────────────────────────────
# 发送消息核心函数
# ─────────────────────────────────────────
function Send-FeishuMessage {
    param(
        [string]$Webhook,
        [string]$Secret = "",
        [hashtable]$Body
    )
    $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $sign = Get-FeishuSign -Secret $Secret -Timestamp $timestamp
    if ($sign) {
        $Body["timestamp"] = "$timestamp"
        $Body["sign"]      = $sign
    }
    $json = $Body | ConvertTo-Json -Depth 10 -Compress
    try {
        $resp = Invoke-RestMethod -Uri $Webhook -Method Post `
            -ContentType "application/json; charset=utf-8" `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($json))
        if ($resp.code -eq 0) {
            Write-Host "  ✅ 飞书消息发送成功" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  ❌ 飞书返回错误: $($resp.msg) (code=$($resp.code))" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  ❌ HTTP 请求失败: $_" -ForegroundColor Red
        return $false
    }
}

# ─────────────────────────────────────────
# 消息模板：纯文本
# ─────────────────────────────────────────
function Build-TextBody {
    param([string]$Text)
    return @{
        msg_type = "text"
        content  = @{ text = $Text }
    }
}

# ─────────────────────────────────────────
# 消息模板：富文本卡片（周报）
# ─────────────────────────────────────────
function Build-WeeklyCard {
    param([string]$ProjectId)
    # 尝试读取项目数据
    $projects = @()
    $tasks    = @()
    $projPath = Join-Path $DATA_DIR "projects.json"
    $taskPath = Join-Path $DATA_DIR "tasks.json"
    if (Test-Path $projPath) { $projects = Get-Content $projPath -Raw | ConvertFrom-Json }
    if (Test-Path $taskPath) { $tasks = Get-Content $taskPath -Raw | ConvertFrom-Json }

    $proj = $projects | Where-Object { $_.id -eq $ProjectId } | Select-Object -First 1
    $projName = if ($proj) { $proj.name } else { $ProjectId }
    $projProgress = if ($proj -and $proj.progress) { $proj.progress } else { "N/A" }

    $now = Get-Date
    $weekStart = $now.AddDays(-7).ToString("yyyy-MM-dd")
    $weekEnd   = $now.ToString("yyyy-MM-dd")

    # 统计本周完成任务
    $completedTasks = $tasks | Where-Object { 
        $_.status -eq "completed" -and $_.projectId -eq $ProjectId
    }
    $urgentTasks = $tasks | Where-Object {
        $_.status -ne "completed" -and $_.projectId -eq $ProjectId -and
        $_.dueDate -and (([datetime]$_.dueDate) - $now).TotalDays -le 3
    }

    $body = @{
        msg_type = "post"
        content  = @{
            post = @{
                "zh_cn" = @{
                    title = "📊 PMO 周报 · $projName · $weekStart ~ $weekEnd"
                    content = @(
                        @(@{ tag="text"; text="项目整体进度：" }, @{ tag="text"; text="$projProgress%"; style=@("bold") }),
                        @(@{ tag="text"; text="本周完成任务：$($completedTasks.Count) 项" }),
                        @(@{ tag="text"; text="紧急待办（3天内到期）：$($urgentTasks.Count) 项"; style=@("red") }),
                        @(@{ tag="text"; text="━━━━━━━━━━━━━━━━━━━━━━━━━━" }),
                        @(@{ tag="text"; text="⚠️ 紧急任务：" })
                    )
                }
            }
        }
    }
    # 追加紧急任务列表
    $urgentTasks | Select-Object -First 5 | ForEach-Object {
        $item = @(@{ tag="text"; text="  • $($_.name) | $($_.assignee) | 截止:$($_.dueDate) [$($_.progress)%]" })
        $body.content.post."zh_cn".content += , $item
    }
    $body.content.post."zh_cn".content += , @(@{ tag="text"; text="━━━━━━━━━━━━━━━━━━━━━━━━━━" })
    $body.content.post."zh_cn".content += , @(@{ tag="text"; text="由 AI-PMO-System 自动生成 · $(Get-Date -Format 'MM-dd HH:mm')" })
    return $body
}

# ─────────────────────────────────────────
# 消息模板：风险预警卡片
# ─────────────────────────────────────────
function Build-AlertCard {
    param([string]$AlertText)
    return @{
        msg_type = "interactive"
        card = @{
            elements = @(
                @{
                    tag = "div"
                    text = @{ tag="lark_md"; content="**⚠️ PMO 风险预警**`n`n$AlertText" }
                },
                @{
                    tag = "hr"
                },
                @{
                    tag = "note"
                    elements = @(@{ tag="plain_text"; content="AI-PMO-System · $(Get-Date -Format 'yyyy-MM-dd HH:mm')" })
                }
            )
            header = @{
                title    = @{ tag="plain_text"; content="PMO 风险预警" }
                template = "red"
            }
        }
    }
}

# ─────────────────────────────────────────
# 主流程
# ─────────────────────────────────────────
$cfg = Load-Config
$webhook = if ($WebhookUrl) { $WebhookUrl } else { $cfg.webhook }
$secret  = if ($cfg.secret) { $cfg.secret } else { "" }

if ($Test) {
    $body = Build-TextBody "✅ AI-PMO-System 飞书通知测试成功！时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Send-FeishuMessage -Webhook $webhook -Secret $secret -Body $body
    exit
}

switch ($Type) {
    "text" {
        if (-not $Message) { Write-Error "请提供 -Message 参数"; exit 1 }
        $body = Build-TextBody $Message
    }
    "weekly" {
        if (-not $ProjectId) { Write-Error "请提供 -ProjectId 参数"; exit 1 }
        $body = Build-WeeklyCard -ProjectId $ProjectId
    }
    "alert" {
        if (-not $Message) { Write-Error "请提供 -Message 参数"; exit 1 }
        $body = Build-AlertCard -AlertText $Message
    }
    default {
        $body = Build-TextBody ($Message -or "PMO 系统通知 · $(Get-Date -Format 'HH:mm')")
    }
}

Send-FeishuMessage -Webhook $webhook -Secret $secret -Body $body
