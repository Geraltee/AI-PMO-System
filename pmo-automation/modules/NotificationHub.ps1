# ============================================================
# NotificationHub.ps1 - 多通道通知集成中心
# 支持：邮件(SMTP) / 飞书 / 企业微信 / 钉钉
# 用法：.\modules\NotificationHub.ps1 -Message "消息内容" [-Channels "feishu,wxwork"]
#       .\modules\NotificationHub.ps1 -Type weekly -ProjectId PRJ-2026-001
# ============================================================

param(
    [string]$Message   = "",
    [string]$Type      = "text",          # text | weekly | alert | task-reminder
    [string]$ProjectId = "",
    [string]$Channels  = "all",           # all | feishu | wxwork | dingtalk | email | 逗号分隔组合
    [string]$To        = "",              # 邮件收件人（逗号分隔）
    [string]$Subject   = "",              # 邮件主题
    [switch]$Test                         # 向所有已配置渠道发测试消息
)

$BASE_DIR    = Split-Path -Parent $MyInvocation.MyCommand.Path
$CONFIG_PATH = Join-Path $BASE_DIR "..\config\notification-config.json"
$DATA_DIR    = Join-Path $BASE_DIR "..\data"

# ─────────────────────────────────────────
# 加载通知配置
# ─────────────────────────────────────────
function Load-NotifConfig {
    if (-not (Test-Path $CONFIG_PATH)) {
        Write-Host "  ⚠️  通知配置文件不存在，请先运行 Setup-Wizard.ps1" -ForegroundColor Yellow
        return $null
    }
    return Get-Content $CONFIG_PATH -Raw | ConvertFrom-Json
}

function Get-EnabledChannels {
    param($Config, [string]$RequestedChannels)
    if (-not $Config) { return @() }
    $enabled = @($Config.enabled)
    if ($RequestedChannels -eq "all") { return $enabled }
    $requested = $RequestedChannels.Split(",") | ForEach-Object { $_.Trim().ToLower() }
    return $enabled | Where-Object { $requested -contains $_.ToLower() }
}

# ─────────────────────────────────────────
# ── 渠道 1：飞书 Webhook ──────────────────
# ─────────────────────────────────────────
function Send-Feishu {
    param($Config, [string]$Msg, [string]$Title = "PMO 通知")
    if (-not $Config -or -not $Config.webhook) { Write-Host "  ⚠️  飞书未配置" -ForegroundColor Yellow; return }
    $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $body = @{ msg_type = "post"; content = @{ post = @{ "zh_cn" = @{
        title   = $Title
        content = @(, @(@{ tag="text"; text=$Msg }))
    }}}}
    # 签名
    if ($Config.secret) {
        $content = "$timestamp`n$($Config.secret)"
        $hmac = New-Object System.Security.Cryptography.HMACSHA256
        $hmac.Key = [System.Text.Encoding]::UTF8.GetBytes($Config.secret)
        $hash = $hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($content))
        $body["timestamp"] = "$timestamp"
        $body["sign"]      = [Convert]::ToBase64String($hash)
    }
    try {
        $resp = Invoke-RestMethod -Uri $Config.webhook -Method Post `
            -ContentType "application/json; charset=utf-8" `
            -Body ([System.Text.Encoding]::UTF8.GetBytes(($body | ConvertTo-Json -Depth 10 -Compress)))
        if ($resp.code -eq 0) { Write-Host "  ✅ [飞书] 发送成功" -ForegroundColor Green }
        else { Write-Host "  ❌ [飞书] 错误: $($resp.msg)" -ForegroundColor Red }
    } catch { Write-Host "  ❌ [飞书] 请求失败: $_" -ForegroundColor Red }
}

# ─────────────────────────────────────────
# ── 渠道 2：企业微信机器人 ────────────────
# ─────────────────────────────────────────
function Send-WxWork {
    param($Config, [string]$Msg, [string]$Title = "")
    if (-not $Config -or -not $Config.webhook) { Write-Host "  ⚠️  企业微信未配置" -ForegroundColor Yellow; return }
    $text = if ($Title) { "**$Title**`n$Msg" } else { $Msg }
    $body = @{
        msgtype  = "markdown"
        markdown = @{ content = $text }
    }
    try {
        $resp = Invoke-RestMethod -Uri $Config.webhook -Method Post `
            -ContentType "application/json; charset=utf-8" `
            -Body ([System.Text.Encoding]::UTF8.GetBytes(($body | ConvertTo-Json -Compress)))
        if ($resp.errcode -eq 0) { Write-Host "  ✅ [企业微信] 发送成功" -ForegroundColor Green }
        else { Write-Host "  ❌ [企业微信] 错误: $($resp.errmsg) (code=$($resp.errcode))" -ForegroundColor Red }
    } catch { Write-Host "  ❌ [企业微信] 请求失败: $_" -ForegroundColor Red }
}

# ─────────────────────────────────────────
# ── 渠道 3：钉钉机器人 ───────────────────
# ─────────────────────────────────────────
function Send-DingTalk {
    param($Config, [string]$Msg, [string]$Title = "PMO 通知")
    if (-not $Config -or -not $Config.webhook) { Write-Host "  ⚠️  钉钉未配置" -ForegroundColor Yellow; return }
    $body = @{
        msgtype  = "markdown"
        markdown = @{ title = $Title; text = "### $Title`n`n$Msg" }
    }
    # 加签
    if ($Config.secret) {
        $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        $content   = "$timestamp`n$($Config.secret)"
        $hmac = New-Object System.Security.Cryptography.HMACSHA256
        $hmac.Key  = [System.Text.Encoding]::UTF8.GetBytes($Config.secret)
        $hash      = $hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($content))
        $sign      = [Uri]::EscapeDataString([Convert]::ToBase64String($hash))
        $url       = "$($Config.webhook)&timestamp=$timestamp&sign=$sign"
    } else {
        $url = $Config.webhook
    }
    try {
        $resp = Invoke-RestMethod -Uri $url -Method Post `
            -ContentType "application/json; charset=utf-8" `
            -Body ([System.Text.Encoding]::UTF8.GetBytes(($body | ConvertTo-Json -Compress)))
        if ($resp.errcode -eq 0) { Write-Host "  ✅ [钉钉] 发送成功" -ForegroundColor Green }
        else { Write-Host "  ❌ [钉钉] 错误: $($resp.errmsg)" -ForegroundColor Red }
    } catch { Write-Host "  ❌ [钉钉] 请求失败: $_" -ForegroundColor Red }
}

# ─────────────────────────────────────────
# ── 渠道 4：邮件（SMTP）─────────────────
# ─────────────────────────────────────────
function Send-EmailNotif {
    param($Config, [string]$ToAddr, [string]$EmailSubject, [string]$Body)
    if (-not $Config) { Write-Host "  ⚠️  邮件未配置" -ForegroundColor Yellow; return }
    $emailConfigPath = Join-Path $BASE_DIR "..\config\email-config.json"
    if (-not (Test-Path $emailConfigPath)) { Write-Host "  ⚠️  email-config.json 不存在" -ForegroundColor Yellow; return }
    $emailCfg = Get-Content $emailConfigPath -Raw | ConvertFrom-Json
    try {
        $pass = ConvertTo-SecureString $emailCfg.password -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential($emailCfg.username, $pass)
        $recipients = $ToAddr.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        Send-MailMessage `
            -From       $emailCfg.username `
            -To         $recipients `
            -Subject    $EmailSubject `
            -Body       $Body `
            -SmtpServer $emailCfg.host `
            -Port       $emailCfg.port `
            -Credential $cred `
            -UseSsl:($emailCfg.ssl) `
            -Encoding   UTF8
        Write-Host "  ✅ [邮件] 已发送至 $ToAddr" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ [邮件] 发送失败: $_" -ForegroundColor Red
    }
}

# ─────────────────────────────────────────
# 内容生成：周报摘要文本
# ─────────────────────────────────────────
function Get-WeeklyText {
    param([string]$ProjectId)
    $now = Get-Date
    $projPath = Join-Path $DATA_DIR "projects.json"
    $taskPath = Join-Path $DATA_DIR "tasks.json"
    $proj = if (Test-Path $projPath) {
        (Get-Content $projPath -Raw | ConvertFrom-Json) | Where-Object { $_.id -eq $ProjectId } | Select-Object -First 1
    }
    $allTasks = if (Test-Path $taskPath) { Get-Content $taskPath -Raw | ConvertFrom-Json } else { @() }
    $projTasks   = $allTasks | Where-Object { $_.projectId -eq $ProjectId }
    $urgentTasks = $projTasks | Where-Object {
        $_.status -ne "completed" -and $_.dueDate -and
        (([datetime]$_.dueDate) - $now).TotalDays -le 3
    }
    $doneTasks = $projTasks | Where-Object { $_.status -eq "completed" }

    $title  = "📊 PMO 周报 · $($proj.name ?? $ProjectId)"
    $period = "$($now.AddDays(-7).ToString('yyyy-MM-dd')) ~ $($now.ToString('yyyy-MM-dd'))"
    $lines = @(
        "**$title**",
        "周期：$period",
        "",
        "项目整体进度：$($proj.progress ?? 'N/A')%",
        "本周完成任务：$($doneTasks.Count) 项",
        "紧急待办（3天内到期）：$($urgentTasks.Count) 项",
        ""
    )
    if ($urgentTasks.Count -gt 0) {
        $lines += "⚠️ 紧急任务："
        $urgentTasks | Select-Object -First 5 | ForEach-Object {
            $lines += "  • $($_.name) | $($_.assignee) | 截止:$($_.dueDate) [$($_.progress)%]"
        }
    }
    $lines += ""
    $lines += "由 AI-PMO-System 自动生成 · $($now.ToString('MM-dd HH:mm'))"
    return [pscustomobject]@{ Title=$title; Text=($lines -join "`n") }
}

# ─────────────────────────────────────────
# 主分发逻辑
# ─────────────────────────────────────────
$config   = Load-NotifConfig
$channels = Get-EnabledChannels -Config $config -RequestedChannels $Channels

Write-Host ""
Write-Host "  ── NotificationHub ─────────────────────────────" -ForegroundColor Cyan
Write-Host "  类型: $Type  |  渠道: $($channels -join ', ')" -ForegroundColor DarkGray
Write-Host ""

if ($Test) {
    $testMsg = "✅ AI-PMO-System 通知测试成功！时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    if ("feishu"   -in $channels) { Send-Feishu   -Config $config.feishu   -Msg $testMsg -Title "PMO 通知测试" }
    if ("wxwork"   -in $channels) { Send-WxWork   -Config $config.wxwork   -Msg $testMsg -Title "PMO 通知测试" }
    if ("dingtalk" -in $channels) { Send-DingTalk -Config $config.dingtalk -Msg $testMsg -Title "PMO 通知测试" }
    if ("email"    -in $channels -and $To) {
        Send-EmailNotif -Config $config.email -ToAddr $To -EmailSubject "PMO 通知测试" -Body $testMsg
    }
    exit 0
}

# 生成消息内容
$msgTitle = if ($Subject) { $Subject } else { "PMO 通知" }
$msgBody  = $Message

switch ($Type) {
    "weekly" {
        if (-not $ProjectId) { Write-Error "请提供 -ProjectId 参数"; exit 1 }
        $weekly   = Get-WeeklyText -ProjectId $ProjectId
        $msgTitle = $weekly.Title
        $msgBody  = $weekly.Text
    }
    "alert" {
        $msgTitle = "⚠️ PMO 风险预警"
        $msgBody  = $Message
    }
    "task-reminder" {
        $msgTitle = "📋 PMO 任务提醒"
        $msgBody  = $Message
    }
}

if (-not $msgBody) { Write-Error "消息内容为空"; exit 1 }

# 分发到各渠道
if ("feishu"   -in $channels) { Send-Feishu   -Config $config.feishu   -Msg $msgBody -Title $msgTitle }
if ("wxwork"   -in $channels) { Send-WxWork   -Config $config.wxwork   -Msg $msgBody -Title $msgTitle }
if ("dingtalk" -in $channels) { Send-DingTalk -Config $config.dingtalk -Msg $msgBody -Title $msgTitle }
if ("email"    -in $channels) {
    $toAddr = if ($To) { $To } else { $config.email?.defaultRecipients }
    if ($toAddr) {
        Send-EmailNotif -Config $config.email -ToAddr $toAddr -EmailSubject $msgTitle -Body $msgBody
    } else {
        Write-Host "  ⚠️  邮件渠道需要指定收件人 (-To)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "  ── 通知分发完成 ─────────────────────────────────" -ForegroundColor Cyan
Write-Host ""
