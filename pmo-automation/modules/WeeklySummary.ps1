<#
.SYNOPSIS
    周会总结 Bot 模块
.DESCRIPTION
    自动收集周报、生成会议纪要、追踪行动项
#>

function Generate-WeeklySummary {
    param(
        [DateTime]$WeekStart = (Get-Date).AddDays(-(Get-Date).DayOfWeek),
        [DateTime]$WeekEnd = $WeekStart.AddDays(6),
        [string]$OutputPath = '.\output\reports'
    )
    
    Write-Host "[WeeklySummary] 生成周会总结..." -ForegroundColor Cyan
    Write-Host "  周期：$($WeekStart.ToString('yyyy-MM-dd')) 至 $($WeekEnd.ToString('yyyy-MM-dd'))" -ForegroundColor Gray
    
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null
    }
    
    # 加载数据
    $dataPath = Join-Path $ScriptDir '..\data'
    $projects = @()
    $tasks = @()
    $employees = @()
    
    if (Test-Path (Join-Path $dataPath 'projects.json')) {
        $projects = Get-Content (Join-Path $dataPath 'projects.json') | ConvertFrom-Json
    }
    if (Test-Path (Join-Path $dataPath 'tasks.json')) {
        $tasks = Get-Content (Join-Path $dataPath 'tasks.json') | ConvertFrom-Json
    }
    if (Test-Path (Join-Path $dataPath 'employees.json')) {
        $employees = Get-Content (Join-Path $dataPath 'employees.json') | ConvertFrom-Json
    }
    
    # 生成本周总结
    $summary = @{
        WeekStart = $WeekStart.ToString('yyyy-MM-dd')
        WeekEnd = $WeekEnd.ToString('yyyy-MM-dd')
        GeneratedAt = Get-Date
        Overview = @{
            TotalProjects = $projects.Count
            ActiveProjects = ($projects | Where-Object { $_.Status -eq 'active' }).Count
            CompletedTasks = 0
            NewTasks = 0
            OverdueTasks = 0
        }
        ProjectUpdates = @()
        TaskSummary = @()
        ActionItems = @()
        Risks = @()
        NextWeekPlan = @()
    }
    
    # 统计任务完成情况
    foreach ($task in $tasks) {
        if ($task.CompletedDate) {
            try {
                $completedDate = [DateTime]::Parse($task.CompletedDate)
                if ($completedDate -ge $WeekStart -and $completedDate -le $WeekEnd) {
                    $summary.Overview.CompletedTasks++
                }
            }
            catch {}
        }
        
        if ($task.CreatedDate) {
            try {
                $createdDate = [DateTime]::Parse($task.CreatedDate)
                if ($createdDate -ge $WeekStart -and $createdDate -le $WeekEnd) {
                    $summary.Overview.NewTasks++
                }
            }
            catch {}
        }
        
        if ($task.DueDate -and $task.Status -ne 'completed') {
            try {
                $dueDate = [DateTime]::Parse($task.DueDate)
                if ($dueDate -lt $WeekEnd) {
                    $summary.Overview.OverdueTasks++
                }
            }
            catch {}
        }
    }
    
    # 生成项目更新
    foreach ($project in $projects) {
        $projectTasks = $tasks | Where-Object { $_.ProjectId -eq $project.ProjectId }
        $completedThisWeek = 0
        $pendingTasks = 0
        
        foreach ($task in $projectTasks) {
            if ($task.Status -eq 'completed' -and $task.CompletedDate) {
                try {
                    if ([DateTime]::Parse($task.CompletedDate) -ge $WeekStart) {
                        $completedThisWeek++
                    }
                }
                catch {}
            }
            if ($task.Status -ne 'completed') {
                $pendingTasks++
            }
        }
        
        $summary.ProjectUpdates += @{
            ProjectId = $project.ProjectId
            ProjectName = $project.ProjectName ?? $project.ProjectId
            Status = $project.Status ?? 'unknown'
            Progress = $project.Progress ?? 0
            CompletedTasksThisWeek = $completedThisWeek
            PendingTasks = $pendingTasks
            Summary = "本周完成 $completedThisWeek 个任务，剩余 $pendingTasks 个任务"
        }
    }
    
    # 生成行动项
    $overdueTasks = $tasks | Where-Object { 
        $_.Status -ne 'completed' -and 
        $_.DueDate -and 
        [DateTime]::Parse($_.DueDate) -lt $WeekEnd 
    }
    
    foreach ($task in $overdueTasks | Select-Object -First 10) {
        $summary.ActionItems += @{
            TaskId = $task.TaskId ?? (New-Guid).ToString().Substring(0, 8)
            Description = $task.TaskName ?? $task.Name
            AssignedTo = $task.AssignedTo ?? '未分配'
            DueDate = $task.DueDate
            Priority = 'high'
            Status = 'open'
        }
    }
    
    # 生成风险提示
    $atRiskProjects = $projects | Where-Object { $_.Status -eq 'delayed' -or $_.RiskLevel -eq 'high' }
    foreach ($project in $atRiskProjects) {
        $summary.Risks += @{
            ProjectId = $project.ProjectId
            ProjectName = $project.ProjectName ?? $project.ProjectId
            RiskDescription = "项目进度延迟或高风险"
            Impact = 'high'
            Mitigation = '需要立即关注并制定应对方案'
        }
    }
    
    # 生成 Markdown 报告
    $reportContent = Generate-WeeklyReportMarkdown -Summary $summary
    $reportFile = Join-Path $OutputPath "weekly-summary-$($WeekStart.ToString('yyyyMMdd')).md"
    $reportContent | Out-File $reportFile -Encoding UTF8
    
    Write-Host "  [OK] 周报已生成：$reportFile" -ForegroundColor Green
    
    # 生成 HTML 版本
    $htmlContent = Generate-WeeklyReportHTML -Summary $summary
    $htmlFile = Join-Path $OutputPath "weekly-summary-$($WeekStart.ToString('yyyyMMdd')).html"
    $htmlContent | Out-File $htmlFile -Encoding UTF8
    
    Write-Host "  [OK] HTML 版本：$htmlFile" -ForegroundColor Green
    
    # 保存 JSON 数据
    $jsonFile = Join-Path $OutputPath "weekly-summary-$($WeekStart.ToString('yyyyMMdd')).json"
    $summary | ConvertTo-Json -Depth 10 | Out-File $jsonFile -Encoding UTF8
    
    return $summary
}

function Generate-WeeklyReportMarkdown {
    param([hashtable]$Summary)
    
    $report = @"
# 周会总结报告

**周期:** $($Summary.WeekStart) 至 $($Summary.WeekEnd)  
**生成时间:** $($Summary.GeneratedAt.ToString('yyyy-MM-dd HH:mm:ss'))

---

## 📊 本周概览

| 指标 | 数值 |
|------|------|
| 总项目数 | $($Summary.Overview.TotalProjects) |
| 进行中项目 | $($Summary.Overview.ActiveProjects) |
| 完成任务 | $($Summary.Overview.CompletedTasks) |
| 新增任务 | $($Summary.Overview.NewTasks) |
| 逾期任务 | $($Summary.Overview.OverdueTasks) |

---

## 📋 项目进展

"@
    
    foreach ($proj in $Summary.ProjectUpdates) {
        $report += @"
### $($proj.ProjectName)
- **状态:** $($proj.Status)
- **进度:** $($proj.Progress)%
- **本周完成:** $($proj.CompletedTasksThisWeek) 个任务
- **待完成任务:** $($proj.PendingTasks) 个
- **说明:** $($proj.Summary)

"@
    }
    
    if ($Summary.ActionItems.Count -gt 0) {
        $report += @"
---

## ✅ 行动项

| 任务 | 负责人 | 截止日期 | 优先级 |
|------|--------|----------|--------|
"@
        foreach ($item in $Summary.ActionItems) {
            $report += "| $($item.Description) | $($item.AssignedTo) | $($item.DueDate) | $($item.Priority) |`n"
        }
    }
    
    if ($Summary.Risks.Count -gt 0) {
        $report += @"
---

## ⚠️ 风险提示

"@
        foreach ($risk in $Summary.Risks) {
            $report += @"
### $($risk.ProjectName)
- **风险描述:** $($risk.RiskDescription)
- **影响程度:** $($risk.Impact)
- **应对建议:** $($risk.Mitigation)

"@
        }
    }
    
    $report += @"
---

*本报告由 PMO 自动化管理系统自动生成*
"@
    
    return $report
}

function Generate-WeeklyReportHTML {
    param([hashtable]$Summary)
    
    $html = @"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>周会总结 - $($Summary.WeekStart) 至 $($Summary.WeekEnd)</title>
    <style>
        body { 
            font-family: 'Segoe UI', 'Microsoft YaHei', sans-serif; 
            max-width: 1000px; 
            margin: 0 auto; 
            padding: 40px 20px;
            background: #f5f7fa;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        .header h1 { margin: 0 0 10px 0; }
        .header p { opacity: 0.9; margin: 5px 0; }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .stat-card h3 { color: #667eea; margin: 0; font-size: 2em; }
        .stat-card p { color: #666; margin: 5px 0 0 0; }
        
        .section {
            background: white;
            padding: 25px;
            border-radius: 10px;
            margin-bottom: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .section h2 { color: #333; border-bottom: 2px solid #667eea; padding-bottom: 10px; }
        
        .project-card {
            border: 1px solid #eee;
            border-radius: 8px;
            padding: 15px;
            margin: 10px 0;
        }
        .project-card h3 { color: #667eea; margin: 0 0 10px 0; }
        .progress-bar {
            background: #eee;
            border-radius: 10px;
            height: 10px;
            margin: 10px 0;
            overflow: hidden;
        }
        .progress-fill {
            background: linear-gradient(90deg, #667eea, #764ba2);
            height: 100%;
            border-radius: 10px;
        }
        
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #eee; }
        th { background: #f8f9fa; }
        
        .priority-high { color: #dc3545; font-weight: bold; }
        .priority-medium { color: #ffc107; }
        .priority-low { color: #28a745; }
    </style>
</head>
<body>
    <div class="header">
        <h1>📅 周会总结报告</h1>
        <p>周期：$($Summary.WeekStart) 至 $($Summary.WeekEnd)</p>
        <p>生成时间：$($Summary.GeneratedAt.ToString('yyyy-MM-dd HH:mm:ss'))</p>
    </div>
    
    <div class="stats-grid">
        <div class="stat-card">
            <h3>$($Summary.Overview.TotalProjects)</h3>
            <p>总项目</p>
        </div>
        <div class="stat-card">
            <h3>$($Summary.Overview.ActiveProjects)</h3>
            <p>进行中</p>
        </div>
        <div class="stat-card">
            <h3>$($Summary.Overview.CompletedTasks)</h3>
            <p>完成任务</p>
        </div>
        <div class="stat-card">
            <h3>$($Summary.Overview.NewTasks)</h3>
            <p>新增任务</p>
        </div>
        <div class="stat-card">
            <h3 style="color: #dc3545;">$($Summary.Overview.OverdueTasks)</h3>
            <p>逾期任务</p>
        </div>
    </div>
    
    <div class="section">
        <h2>📋 项目进展</h2>
"@
    
    foreach ($proj in $Summary.ProjectUpdates) {
        $html += @"
        <div class="project-card">
            <h3>$($proj.ProjectName)</h3>
            <p>状态：$($proj.Status) | 本周完成：$($proj.CompletedTasksThisWeek) 任务 | 待完成：$($proj.PendingTasks)</p>
            <div class="progress-bar">
                <div class="progress-fill" style="width: $($proj.Progress)%"></div>
            </div>
            <p>进度：$($proj.Progress)%</p>
        </div>
"@
    }
    
    $html += @"
    </div>
</body>
</html>
"@
    
    return $html
}

function Collect-WeeklyReports {
    param(
        [DateTime]$WeekStart,
        [DateTime]$WeekEnd
    )
    
    # 收集各项目的周报数据
    # 可以通过邮件、API 或文件方式收集
    Write-Host "[WeeklySummary] 收集周报数据..." -ForegroundColor Cyan
    
    $reports = @()
    
    # TODO: 实现实际的数据收集逻辑
    # 可以从以下来源收集：
    # 1. 邮件回复
    # 2. 表单提交
    # 3. API 接口
    # 4. 文件上传
    
    return $reports
}
