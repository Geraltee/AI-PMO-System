<#
.SYNOPSIS
    邮件提醒系统模块
.DESCRIPTION
    发送项目到期提醒、启动通知等邮件（通过 OpenClaw message 工具或 SMTP）
#>

function Send-ProjectReminders {
    param(
        [string]$ReminderType = 'all',  # all, overdue, upcoming, kickoff
        [switch]$DryRun
    )
    
    Write-Host "[EmailNotifier] 发送项目提醒..." -ForegroundColor Cyan
    
    # 获取提醒数据
    $alerts = Get-TimelineAlerts -DaysThreshold 3
    $reminders = @()
    
    switch ($ReminderType) {
        'overdue' {
            $reminders = $alerts | Where-Object { $_.Type -eq 'overdue' }
        }
        'upcoming' {
            $reminders = $alerts | Where-Object { $_.Type -eq 'upcoming' }
        }
        'kickoff' {
            $reminders = Get-UpcomingKickoffs
        }
        'all' {
            $reminders = $alerts
        }
    }
    
    if ($reminders.Count -eq 0) {
        Write-Host "  [INFO] 暂无需要发送的提醒" -ForegroundColor Yellow
        return
    }
    
    Write-Host "  准备发送 $($reminders.Count) 条提醒" -ForegroundColor Gray
    
    foreach ($reminder in $reminders) {
        if ($DryRun) {
            Write-Host "  [DRY RUN] 跳过发送：$($reminder.Message)" -ForegroundColor Cyan
            continue
        }
        
        Send-Reminder -Reminder $reminder
    }
    
    Write-Host "`n[OK] 提醒发送完成" -ForegroundColor Green
}

function Send-Reminder {
    param([hashtable]$Reminder)
    
    $subject = switch ($Reminder.Type) {
        'overdue' { "🚨 逾期提醒：$($Reminder.Item.Name)" }
        'upcoming' { "⏰ 即将到期：$($Reminder.Item.Name)" }
        'kickoff' { "📢 项目启动通知" }
        default { "项目提醒" }
    }
    
    $body = Generate-ReminderEmailBody -Reminder $Reminder
    
    Write-Host "  发送提醒：$subject" -ForegroundColor Gray
    
    # 使用 SMTP 发送邮件
    try {
        $htmlBody = @"
<html>
<body>
<h2>$subject</h2>
<p>$body</p>
<hr>
<p style="color: #666; font-size: 12px;">此消息由 PMO 自动化管理系统发送<br>
发送时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
</body>
</html>
"@
        
        # 获取收件人（从员工数据中获取邮箱）
        $recipientEmail = Get-RecipientEmail -Reminder $Reminder
        
        if ($recipientEmail) {
            $sendResult = Send-EmailViaSMTP -To $recipientEmail -Subject $subject -Body $htmlBody -IsHtml $true
            
            if ($sendResult) {
                Write-Host "    [OK] 邮件已发送到 $recipientEmail" -ForegroundColor Green
                Log-EmailSent -Subject $subject -Body $htmlBody -Type $Reminder.Type -Recipients @($recipientEmail)
            } else {
                Write-Host "    [ERROR] 邮件发送失败" -ForegroundColor Red
            }
        } else {
            Write-Host "    [WARN] 未找到收件人邮箱地址" -ForegroundColor Yellow
        }
        
    }
    catch {
        Write-Host "    [ERROR] 发送失败：$_" -ForegroundColor Red
    }
}

function Get-RecipientEmail {
    param([hashtable]$Reminder)
    
    # 从员工数据中查找邮箱
    $employeesPath = Join-Path $PSScriptRoot '..\data\employees.json'
    if (Test-Path $employeesPath) {
        $employees = Get-Content $employeesPath | ConvertFrom-Json
        
        # 根据提醒类型获取相关人员的邮箱
        if ($Reminder.Item.AssignedTo) {
            $assignee = $employees | Where-Object { $_.Name -eq $Reminder.Item.AssignedTo -or $_.Email -eq $Reminder.Item.AssignedTo }
            if ($assignee) {
                return $assignee.Email
            }
        }
        
        # 默认返回项目经理邮箱
        $projectsPath = Join-Path $PSScriptRoot '..\data\projects.json'
        if (Test-Path $projectsPath) {
            $projects = Get-Content $projectsPath | ConvertFrom-Json
            $project = $projects | Where-Object { $_.ProjectName -eq $Reminder.Item.Name -or $_.ProjectId -eq $Reminder.Item.ProjectId }
            if ($project -and $project.ProjectManager) {
                $pm = $employees | Where-Object { $_.Name -eq $project.ProjectManager }
                if ($pm) {
                    return $pm.Email
                }
            }
        }
    }
    
    return $null
}

function Generate-ReminderEmailBody {
    param([hashtable]$Reminder)
    
    $body = ""
    
    if ($Reminder.Type -eq 'overdue') {
        $item = $Reminder.Item
        $body = @"
您好，

以下项目/任务已逾期，请及时处理：

项目名称：$($item.Name)
逾期天数：$($item.DaysOverdue) 天
截止日期：$($item.DueDate)

请尽快安排处理并更新进度。

如有问题，请及时与项目经理沟通。
"@
    }
    elseif ($Reminder.Type -eq 'upcoming') {
        $item = $Reminder.Item
        $body = @"
您好，

以下项目/任务即将到期，请注意安排：

项目名称：$($item.Name)
剩余天数：$($item.DaysRemaining) 天
截止日期：$($item.DueDate)

请确保按时完成并更新状态。

祝工作顺利！
"@
    }
    elseif ($Reminder.Type -eq 'kickoff') {
        $item = $Reminder.Item
        $body = @"
您好，

新项目即将启动，请做好准备：

项目名称：$($item.ProjectName)
启动日期：$($item.StartDate)
项目经理：$($item.ProjectManager)

请准时参加项目启动会议。

会议详情将另行通知。
"@
    }
    
    return $body
}

function Get-UpcomingKickoffs {
    $kickoffs = @()
    
    $projectsPath = Join-Path $ScriptDir '..\data\projects.json'
    if (Test-Path $projectsPath) {
        $projects = Get-Content $projectsPath | ConvertFrom-Json
        $today = Get-Date
        
        foreach ($project in $projects) {
            if ($project.StartDate) {
                try {
                    $startDate = [DateTime]::Parse($project.StartDate)
                    $daysUntilStart = ($startDate - $today).Days
                    
                    if ($daysUntilStart -ge 0 -and $daysUntilStart -le 3) {
                        $kickoffs += @{
                            Type = 'kickoff'
                            ProjectName = $project.ProjectName ?? $project.ProjectId
                            StartDate = $project.StartDate
                            ProjectManager = $project.ProjectManager ?? '待定'
                            DaysUntilStart = $daysUntilStart
                        }
                    }
                }
                catch {}
            }
        }
    }
    
    return $kickoffs
}

function Send-ProjectKickoffNotification {
    param(
        [string]$ProjectId,
        [array]$Recipients
    )
    
    Write-Host "[EmailNotifier] 发送项目启动通知..." -ForegroundColor Cyan
    
    $projectsPath = Join-Path $ScriptDir '..\data\projects.json'
    $project = $null
    
    if (Test-Path $projectsPath) {
        $projects = Get-Content $projectsPath | ConvertFrom-Json
        $project = $projects | Where-Object { $_.ProjectId -eq $ProjectId }
    }
    
    if (-not $project) {
        Write-Host "  [ERROR] 项目不存在：$ProjectId" -ForegroundColor Red
        return
    }
    
    $subject = "📢 项目启动通知：$($project.ProjectName)"
    $body = @"
各位同事，

很高兴通知大家，新项目正式启动！

项目名称：$($project.ProjectName)
项目 ID: $ProjectId
启动日期：$($project.StartDate ?? '待定')
预计结束：$($project.EndDate ?? '待定')
项目经理：$($project.ProjectManager ?? '待定')

项目目标：
$($project.Objectives ?? '详见项目文档')

项目启动会议将于近期召开，具体时间和地点将另行通知。

请各位做好准备工作！

此致
敬礼

PMO 自动化管理系统
"@
    
    # 记录发送
    Log-EmailSent -Subject $subject -Body $body -Type 'kickoff' -Recipients $Recipients
    
    Write-Host "  [OK] 启动通知已记录（实际发送需配置 OpenClaw message 通道）" -ForegroundColor Green
}

function Log-EmailSent {
    param(
        [string]$Subject,
        [string]$Body,
        [string]$Type,
        [array]$Recipients
    )
    
    $logPath = Join-Path $ScriptDir '..\output\email-log.json'
    $logs = @()
    
    if (Test-Path $logPath) {
        $logs = Get-Content $logPath | ConvertFrom-Json
    }
    
    $log = @{
        Timestamp = Get-Date
        Subject = $Subject
        Type = $Type
        Body = $Body
        Recipients = $Recipients
        Status = 'logged'
    }
    
    $logs += $log
    
    # 只保留最近 100 条记录
    if ($logs.Count -gt 100) {
        $logs = $logs | Select-Object -Last 100
    }
    
    $logs | ConvertTo-Json -Depth 10 | Out-File $logPath -Encoding UTF8
}

function Send-StatusUpdateNotification {
    param(
        [string]$ProjectId,
        [string]$UpdateType = 'progress'  # progress, milestone, risk, completion
        [string]$Message
    )
    
    $subject = switch ($UpdateType) {
        'progress' { "📊 项目进度更新" }
        'milestone' { "🎯 里程碑达成" }
        'risk' { "⚠️ 风险提示" }
        'completion' { "✅ 项目完成" }
        default { "项目更新" }
    }
    
    $body = @"
项目更新通知

项目 ID: $ProjectId
更新类型：$UpdateType

$Message

---
PMO 自动化管理系统
$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
    
    Log-EmailSent -Subject $subject -Body $body -Type $UpdateType
}

function Send-EmailViaSMTP {
    param(
        [string]$To,
        [string]$Subject,
        [string]$Body,
        [bool]$IsHtml = $true
    )
    
    # SMTP 配置
    $smtpServer = "smtp-mail.outlook.com"
    $smtpPort = 587
    $smtpUser = "openclawPMO@outlook.com"
    $smtpPass = "PMOopenclaw1"
    
    try {
        # 创建邮件
        $mail = New-Object Net.Mail.MailMessage
        $mail.From = $smtpUser
        $mail.FromDisplayName = "AI PMO System"
        $mail.To.Add($To)
        $mail.Subject = $Subject
        $mail.Body = $Body
        $mail.IsBodyHtml = $IsHtml
        
        # 创建 SMTP 客户端
        $smtp = New-Object Net.Mail.SmtpClient($smtpServer, $smtpPort)
        $smtp.Credentials = New-Object Net.NetworkCredential($smtpUser, $smtpPass)
        $smtp.EnableSsl = $true
        
        $smtp.Send($mail)
        
        $mail.Dispose()
        $smtp.Dispose()
        
        return $true
    }
    catch {
        Write-Host "    [ERROR] SMTP 发送失败：$($_.Exception.Message)" -ForegroundColor Red
        if ($mail) { $mail.Dispose() }
        if ($smtp) { $smtp.Dispose() }
        return $false
    }
}

function Test-EmailConfiguration {
    Write-Host "[EmailNotifier] 测试邮件配置..." -ForegroundColor Cyan
    
    # 检查配置
    $configPath = Join-Path $ScriptDir '..\config\settings.json'
    if (Test-Path $configPath) {
        $config = Get-Content $configPath | ConvertFrom-Json
        Write-Host "  [OK] 配置文件存在" -ForegroundColor Green
        
        if ($config.EmailEnabled) {
            Write-Host "  [OK] 邮件功能已启用" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] 邮件功能未启用" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [WARN] 配置文件不存在" -ForegroundColor Yellow
    }
    
    # 测试 SMTP 连接
    Write-Host "  测试 SMTP 连接..." -ForegroundColor Gray
    $testResult = Send-EmailViaSMTP -To $smtpUser -Subject "SMTP 配置测试" -Body "这是一封测试邮件，确认 SMTP 配置正常。" -IsHtml $false
    
    if ($testResult) {
        Write-Host "  [OK] SMTP 测试成功" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] SMTP 测试失败，请检查账号密码和网络连接" -ForegroundColor Red
    }
    
    # 测试发送日志功能
    $testReminder = @{
        Type = 'test'
        Message = '测试提醒'
        Item = @{ Name = '测试项目' }
    }
    
    Send-Reminder -Reminder $testReminder
    Write-Host "  [OK] 测试完成" -ForegroundColor Green
}
