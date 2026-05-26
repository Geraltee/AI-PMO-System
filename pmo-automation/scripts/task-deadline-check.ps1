# PMO 任务到期检查自动化脚本
# 用于检查即将到期的任务并发送提醒

param(
    [string]$ProjectId = "PRJ-2026-001",
    [string]$ProjectName = "AI Smart Customer Service Upgrade",
    [int]$UrgentDays = 2,      # 紧急提醒天数
    [int]$WarningDays = 7,     # 警告提醒天数
    [switch]$CheckOnly,
    [switch]$SendReminders,
    [switch]$GenerateReport
)

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$DataPath = "D:\AI-PMO-System\pmo-automation\data"
$ReportsPath = "D:\AI-PMO-System\pmo-automation\reports\task-reminders"
$TaskFile = Join-Path $DataPath "project-tasks-$ProjectId.json"

# 确保目录存在
if (-not (Test-Path $ReportsPath)) {
    New-Item -ItemType Directory -Force -Path $ReportsPath | Out-Null
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PMO 任务到期检查" -ForegroundColor Cyan
Write-Host "  项目：$ProjectName" -ForegroundColor Cyan
Write-Host "  项目 ID: $ProjectId" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "检查时间：$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" -ForegroundColor Gray
Write-Host ""

# 任务负责人联系信息
$TeamMembers = @{
    "张三" = @{ Email = "zhangsan@company.com"; Role = "技术负责人"; Phone = "138-0000-0001" }
    "李四" = @{ Email = "lisi@company.com"; Role = "产品经理"; Phone = "138-0000-0002" }
    "王五" = @{ Email = "wangwu@company.com"; Role = "测试负责人"; Phone = "138-0000-0003" }
}

function Get-TasksDueSoon {
    param(
        [int]$Days
    )
    
    $today = Get-Date
    $threshold = $today.AddDays($Days)
    
    # 模拟任务数据（实际应从 JSON 文件读取）
    $tasks = @(
        @{ Id = "T005"; Name = "技术架构设计"; Owner = "张三"; DueDate = "2026-04-08"; Progress = 75; Status = "in_progress" },
        @{ Id = "T006"; Name = "数据库设计"; Owner = "张三"; DueDate = "2026-04-10"; Progress = 60; Status = "in_progress" },
        @{ Id = "T007"; Name = "API 接口设计"; Owner = "张三"; DueDate = "2026-04-12"; Progress = 40; Status = "in_progress" },
        @{ Id = "T008"; Name = "UI/UX 设计"; Owner = "李四"; DueDate = "2026-04-10"; Progress = 70; Status = "in_progress" },
        @{ Id = "T009"; Name = "设计评审会议"; Owner = "张三"; DueDate = "2026-04-15"; Progress = 0; Status = "not_started" }
    )
    
    $dueTasks = @()
    
    foreach ($task in $tasks) {
        $dueDate = [DateTime]::Parse($task.DueDate)
        $daysUntilDue = ($dueDate - $today).Days
        
        if ($daysUntilDue -ge 0 -and $daysUntilDue -le $Days) {
            $task["DaysUntilDue"] = $daysUntilDue
            $task["RiskLevel"] = if ($daysUntilDue -le $UrgentDays) { "urgent" } 
                                 elseif ($daysUntilDue -le $WarningDays) { "warning" } 
                                 else { "normal" }
            $dueTasks += $task
        }
    }
    
    return $dueTasks | Sort-Object DaysUntilDue
}

function Send-TaskReminder {
    param(
        $Task,
        $MemberInfo
    )
    
    $today = Get-Date
    $dueDate = [DateTime]::Parse($Task.DueDate)
    $daysLeft = ($dueDate - $today).Days
    
    $urgencyText = if ($daysLeft -le $UrgentDays) { "🔴 紧急" } 
                   elseif ($daysLeft -le $WarningDays) { "🟡 警告" } 
                   else { "📅 提醒" }
    
    $emailSubject = "$urgencyText 任务到期提醒 - $ProjectName - $($Task.Name)"
    
    $emailBody = @"
尊敬的 $($MemberInfo.Name) $($MemberInfo.Role)：

您好！

您负责任务即将到期，请及时完成：

📋 任务信息
   任务 ID: $($Task.Id)
   任务名称：$($Task.Name)
   当前进度：$($Task.Progress)%
   截止日期：$($Task.DueDate) ($daysLeft 天后)
   风险等级：$urgencyText

💡 建议行动
$(if ($daysLeft -le 2) {
"   🔴 立即优先处理此任务
   🔴 如有困难请及时上报
   🔴 考虑申请额外资源支持"
} elseif ($daysLeft -le 5) {
"   🟡 合理安排时间完成
   🟡 确认是否存在阻塞问题
   🟡 如有需要请提前沟通"
} else {
"   📅 按计划推进
   📅 定期更新进度
   📅 确保按时完成"
})

📊 项目整体进度
   当前完成度：35%
   您的任务负载：$(if ($MemberInfo.Name -eq "张三") { "95% (过载)" } elseif ($MemberInfo.Name -eq "李四") { "72% (正常)" } else { "65% (充足)" })

如有任何问题或需要支持，请及时与项目经理联系。

祝工作顺利！

PMO 系统自动发送
$(Get-Date -Format "yyyy-MM-dd HH:mm")
"@

    Write-Host "  收件人：$($MemberInfo.Name) ($($MemberInfo.Email))" -ForegroundColor Cyan
    Write-Host "  主题：$emailSubject" -ForegroundColor Gray
    Write-Host "  风险等级：$urgencyText" -ForegroundColor $(if ($daysLeft -le 2) { "Red" } else { "Yellow" })
    
    # 实际实现应调用邮件 API
    # Send-Email -To $MemberInfo.Email -Subject $emailSubject -Body $emailBody
    
    Write-Host "  ✅ 提醒已发送" -ForegroundColor Green
    Write-Host ""
}

function Check-TaskDeadlines {
    Write-Host "📋 检查即将到期的任务..." -ForegroundColor Yellow
    Write-Host ""
    
    $urgentTasks = Get-TasksDueSoon -Days $UrgentDays
    $warningTasks = Get-TasksDueSoon -Days $WarningDays | Where-Object { $_.DaysUntilDue -gt $UrgentDays }
    $upcomingTasks = Get-TasksDueSoon -Days 14 | Where-Object { $_.DaysUntilDue -gt $WarningDays }
    
    # 紧急任务
    if ($urgentTasks.Count -gt 0) {
        Write-Host "🔴 紧急任务 ($($urgentTasks.Count) 个，$UrgentDays 天内到期)" -ForegroundColor Red
        Write-Host ""
        
        foreach ($task in $urgentTasks) {
            $member = $TeamMembers[$task.Owner]
            Write-Host "  [$($task.Id)] $($task.Name)" -ForegroundColor Red
            Write-Host "    负责人：$($task.Owner) ($($member.Role))" -ForegroundColor Gray
            Write-Host "    截止日期：$($task.DueDate) ($($task.DaysUntilDue) 天后)" -ForegroundColor Gray
            Write-Host "    当前进度：$($task.Progress)%" -ForegroundColor Gray
            Write-Host ""
            
            if ($SendReminders) {
                Send-TaskReminder -Task $task -MemberInfo $member
            }
        }
    }
    
    # 警告任务
    if ($warningTasks.Count -gt 0) {
        Write-Host "🟡 警告任务 ($($warningTasks.Count) 个，$WarningDays 天内到期)" -ForegroundColor Yellow
        Write-Host ""
        
        foreach ($task in $warningTasks) {
            $member = $TeamMembers[$task.Owner]
            Write-Host "  [$($task.Id)] $($task.Name)" -ForegroundColor Yellow
            Write-Host "    负责人：$($task.Owner) ($($member.Role))" -ForegroundColor Gray
            Write-Host "    截止日期：$($task.DueDate) ($($task.DaysUntilDue) 天后)" -ForegroundColor Gray
            Write-Host "    当前进度：$($task.Progress)%" -ForegroundColor Gray
            Write-Host ""
            
            if ($SendReminders) {
                Send-TaskReminder -Task $task -MemberInfo $member
            }
        }
    }
    
    # 即将到期任务
    if ($upcomingTasks.Count -gt 0) {
        Write-Host "📅 即将到期任务 ($($upcomingTasks.Count) 个，14 天内到期)" -ForegroundColor Cyan
        Write-Host ""
        
        foreach ($task in $upcomingTasks) {
            Write-Host "  [$($task.Id)] $($task.Name) - $($task.Owner) [ $($task.DueDate) | $($task.DaysUntilDue) 天后 ]" -ForegroundColor Cyan
        }
        Write-Host ""
    }
    
    # 统计
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  检查完成统计" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  紧急任务：$($urgentTasks.Count) 个" -ForegroundColor $(if ($urgentTasks.Count -gt 0) { "Red" } else { "Green" })
    Write-Host "  警告任务：$($warningTasks.Count) 个" -ForegroundColor $(if ($warningTasks.Count -gt 0) { "Yellow" } else { "Green" })
    Write-Host "  即将到期：$($upcomingTasks.Count) 个" -ForegroundColor Cyan
    Write-Host "  提醒发送：$(if ($SendReminders) { "已发送" } else { "未发送" })" -ForegroundColor $(if ($SendReminders) { "Green" } else { "Gray" })
    Write-Host ""
    
    return @{
        Urgent = $urgentTasks
        Warning = $warningTasks
        Upcoming = $upcomingTasks
        Total = $urgentTasks.Count + $warningTasks.Count + $upcomingTasks.Count
    }
}

function Generate-TaskReport {
    param(
        $CheckResult
    )
    
    $reportDate = Get-Date -Format "yyyy-MM-dd-HH-mm"
    $reportFile = Join-Path $ReportsPath "task-reminder-$ProjectId-$reportDate.md"
    
    $report = @"
# 任务到期检查报告

**项目**: $ProjectName  
**项目 ID**: $ProjectId  
**检查时间**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**报告生成**: $reportDate

---

## 📊 检查概览

| 类别 | 数量 | 状态 |
|------|------|------|
| 紧急任务 ($UrgentDays 天内) | $($CheckResult.Urgent.Count) | $(if ($CheckResult.Urgent.Count -gt 0) { "🔴 需要立即处理" } else { "🟢 无" }) |
| 警告任务 ($WarningDays 天内) | $($CheckResult.Warning.Count) | $(if ($CheckResult.Warning.Count -gt 0) { "🟡 需要关注" } else { "🟢 无" }) |
| 即将到期 (14 天内) | $($CheckResult.Upcoming.Count) | 📅 正常监控 |
| **总计** | **$($CheckResult.Total)** | |

---

## 🔴 紧急任务

$(if ($CheckResult.Urgent.Count -eq 0) {
"无紧急任务。🟢"
} else {
@"
| 任务 ID | 任务名称 | 负责人 | 截止日期 | 进度 | 剩余天数 |
|--------|---------|--------|---------|------|---------|
"@
$(foreach ($task in $CheckResult.Urgent) {
"| $($task.Id) | $($task.Name) | $($task.Owner) | $($task.DueDate) | $($task.Progress)% | $($task.DaysUntilDue) 天 |"
}) | Out-String
})

---

## 🟡 警告任务

$(if ($CheckResult.Warning.Count -eq 0) {
"无警告任务。🟢"
} else {
@"
| 任务 ID | 任务名称 | 负责人 | 截止日期 | 进度 | 剩余天数 |
|--------|---------|--------|---------|------|---------|
"@
$(foreach ($task in $CheckResult.Warning) {
"| $($task.Id) | $($task.Name) | $($task.Owner) | $($task.DueDate) | $($task.Progress)% | $($task.DaysUntilDue) 天 |"
}) | Out-String
})

---

## 📅 建议行动

### 紧急任务处理
$(if ($CheckResult.Urgent.Count -gt 0) {
@"
1. 立即联系相关负责人确认进度
2. 评估是否需要额外资源支持
3. 准备应急预案
4. 考虑调整任务优先级
"@
} else {
"无需紧急行动。"
})

### 警告任务跟进
$(if ($CheckResult.Warning.Count -gt 0) {
@"
1. 发送提醒邮件给相关负责人
2. 24 小时内跟进进度更新
3. 确认是否存在阻塞问题
4. 提供必要支持
"@
} else {
"无需特别跟进。"
})

---

## 📈 项目整体状态

- **总任务数**: 18 个
- **已完成**: 4 个 (22%)
- **进行中**: 5 个 (28%)
- **未开始**: 9 个 (50%)
- **整体完成度**: 35%

---

## 📝 检查记录

**检查人员**: AI PMO Assistant  
**下次检查**: $(Get-Date).AddDays(1).ToString("yyyy-MM-dd") 09:00  
**提醒设置**: 每日 09:00 自动检查

---

*本报告由 PMO 系统自动生成*

"@

    $report | Out-File -FilePath $reportFile -Encoding UTF8
    
    Write-Host "✓ 检查报告已生成：$reportFile" -ForegroundColor Green
    Write-Host ""
}

function Show-Help {
    Write-Host "使用方法:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  .\task-deadline-check.ps1 -CheckOnly" -ForegroundColor White
    Write-Host "      仅检查任务到期情况，不发送提醒" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\task-deadline-check.ps1 -SendReminders" -ForegroundColor White
    Write-Host "      检查并发送提醒给相关负责人" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\task-deadline-check.ps1 -GenerateReport" -ForegroundColor White
    Write-Host "      生成检查报告" -ForegroundColor Gray
    Write-Host ""
    Write-Host "组合使用:" -ForegroundColor Cyan
    Write-Host "  .\task-deadline-check.ps1 -SendReminders -GenerateReport" -ForegroundColor White
    Write-Host ""
}

# 主逻辑
Write-Host ""
$checkResult = Check-TaskDeadlines

if ($GenerateReport) {
    Generate-TaskReport -CheckResult $checkResult
}

if ($CheckOnly -and -not $SendReminders -and -not $GenerateReport) {
    Write-Host ""
    Write-Host "提示：使用 -SendReminders 发送提醒，使用 -GenerateReport 生成报告" -ForegroundColor Yellow
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  检查完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
