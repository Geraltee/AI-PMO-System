<#
.SYNOPSIS
    时间节点追踪模块
.DESCRIPTION
    设置和追踪项目时间节点，提供延期预警
#>

function Track-ProjectTimelines {
    param(
        [string]$ProjectId = 'all',
        [switch]$CheckOverdue
    )
    
    Write-Host "[Timeline] 开始追踪项目时间节点..." -ForegroundColor Cyan
    
    # 加载数据
    $dataPath = Join-Path $ScriptDir '..\data'
    $projects = Get-Content (Join-Path $dataPath 'projects.json') | ConvertFrom-Json
    $tasks = Get-Content (Join-Path $dataPath 'tasks.json') | ConvertFrom-Json
    
    if ($ProjectId -ne 'all') {
        $projects = $projects | Where-Object { $_.ProjectId -eq $ProjectId }
        $tasks = $tasks | Where-Object { $_.ProjectId -eq $ProjectId }
    }
    
    $today = Get-Date
    $trackingResults = @{
        Projects = @()
        Milestones = @()
        OverdueItems = @()
        UpcomingDeadlines = @()
    }
    
    # 追踪项目级别时间节点
    foreach ($project in $projects) {
        $projectStatus = Track-ProjectTimeline -Project $project -Today $today
        
        $trackingResults.Projects += $projectStatus
        
        if ($projectStatus.IsOverdue) {
            $trackingResults.OverdueItems += @{
                Type = 'project'
                Name = $project.ProjectName ?? $project.ProjectId
                DueDate = $project.EndDate
                DaysOverdue = $projectStatus.DaysOverdue
            }
        }
        
        if ($projectStatus.DaysUntilDue -le 7 -and $projectStatus.DaysUntilDue -ge 0) {
            $trackingResults.UpcomingDeadlines += @{
                Type = 'project'
                Name = $project.ProjectName ?? $project.ProjectId
                DueDate = $project.EndDate
                DaysRemaining = $projectStatus.DaysUntilDue
            }
        }
    }
    
    # 追踪任务级别时间节点
    foreach ($task in $tasks) {
        if ($task.DueDate) {
            try {
                $dueDate = [DateTime]::Parse($task.DueDate)
                $daysUntilDue = ($dueDate - $today).Days
                
                if ($daysUntilDue -lt 0 -and $task.Status -ne 'completed') {
                    $trackingResults.OverdueItems += @{
                        Type = 'task'
                        Name = $task.TaskName ?? $task.Name
                        ProjectId = $task.ProjectId
                        DueDate = $task.DueDate
                        DaysOverdue = [math]::Abs($daysUntilDue)
                    }
                }
                elseif ($daysUntilDue -le 3 -and $daysUntilDue -ge 0 -and $task.Status -ne 'completed') {
                    $trackingResults.UpcomingDeadlines += @{
                        Type = 'task'
                        Name = $task.TaskName ?? $task.Name
                        ProjectId = $task.ProjectId
                        DueDate = $task.DueDate
                        DaysRemaining = $daysUntilDue
                    }
                }
            }
            catch {
                # 日期解析失败，跳过
            }
        }
    }
    
    # 生成里程碑
    $trackingResults.Milestones = Generate-Milestones -Projects $projects -Tasks $tasks
    
    # 输出结果
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  时间节点追踪报告" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "📊 项目状态概览:" -ForegroundColor Yellow
    foreach ($proj in $trackingResults.Projects) {
        $statusIcon = if ($proj.IsOverdue) { '🔴' } elseif ($proj.DaysUntilDue -le 7) { '🟡' } else { '🟢' }
        Write-Host "  $statusIcon $($proj.Name): $($proj.Status) (剩余 $($proj.DaysUntilDue) 天)" -ForegroundColor $(if ($proj.IsOverdue) { 'Red' } elseif ($proj.DaysUntilDue -le 7) { 'Yellow' } else { 'Green' })
    }
    
    if ($trackingResults.OverdueItems.Count -gt 0) {
        Write-Host "`n🚨 逾期项目/任务 ($($trackingResults.OverdueItems.Count)):" -ForegroundColor Red
        foreach ($item in $trackingResults.OverdueItems) {
            Write-Host "  ! $($item.Name) - 逾期 $($item.DaysOverdue) 天" -ForegroundColor Red
        }
    }
    
    if ($trackingResults.UpcomingDeadlines.Count -gt 0) {
        Write-Host "`n⏰ 即将到期 ($($trackingResults.UpcomingDeadlines.Count)):" -ForegroundColor Yellow
        foreach ($item in $trackingResults.UpcomingDeadlines) {
            Write-Host "  ⚠ $($item.Name) - 剩余 $($item.DaysRemaining) 天" -ForegroundColor Yellow
        }
    }
    
    # 保存追踪结果
    $outputPath = Join-Path $dataPath 'timeline-tracking.json'
    $trackingResults | Add-Member -NotePropertyName 'LastUpdated' -NotePropertyValue (Get-Date) -Force
    $trackingResults | ConvertTo-Json -Depth 10 | Out-File $outputPath -Encoding UTF8
    
    Write-Host "`n[OK] 时间节点追踪完成" -ForegroundColor Green
    Write-Host "     数据已保存：timeline-tracking.json" -ForegroundColor Gray
    
    return $trackingResults
}

function Track-ProjectTimeline {
    param(
        [object]$Project,
        [DateTime]$Today
    )
    
    $result = @{
        ProjectId = $project.ProjectId
        Name = $project.ProjectName ?? $project.ProjectId
        Status = 'on-track'
        IsOverdue = $false
        DaysUntilDue = 0
        DaysOverdue = 0
        Progress = 0
    }
    
    if ($project.EndDate) {
        try {
            $endDate = [DateTime]::Parse($project.EndDate)
            $daysUntilDue = ($endDate - $Today).Days
            $result.DaysUntilDue = $daysUntilDue
            
            if ($daysUntilDue -lt 0) {
                $result.IsOverdue = $true
                $result.DaysOverdue = [math]::Abs($daysUntilDue)
                $result.Status = 'overdue'
            }
            elseif ($daysUntilDue -le 7) {
                $result.Status = 'critical'
            }
            elseif ($daysUntilDue -le 14) {
                $result.Status = 'warning'
            }
        }
        catch {
            $result.Status = 'unknown'
        }
    }
    
    # 计算进度
    if ($project.Progress) {
        $result.Progress = $project.Progress
    }
    elseif ($project.StartDate -and $project.EndDate) {
        try {
            $startDate = [DateTime]::Parse($project.StartDate)
            $endDate = [DateTime]::Parse($project.EndDate)
            $totalDays = ($endDate - $startDate).Days
            $elapsedDays = ($Today - $startDate).Days
            
            if ($totalDays -gt 0) {
                $result.Progress = [math]::Min(100, [math]::Round(($elapsedDays / $totalDays) * 100))
            }
        }
        catch {
            # 进度计算失败
        }
    }
    
    return $result
}

function Generate-Milestones {
    param(
        [array]$Projects,
        [array]$Tasks
    )
    
    $milestones = @()
    
    foreach ($project in $projects) {
        # 项目关键里程碑
        if ($project.StartDate) {
            $milestones += @{
                ProjectId = $project.ProjectId
                Name = "项目启动"
                Date = $project.StartDate
                Type = 'start'
            }
        }
        
        if ($project.EndDate) {
            $milestones += @{
                ProjectId = $project.ProjectId
                Name = "项目交付"
                Date = $project.EndDate
                Type = 'end'
            }
        }
        
        # 阶段里程碑
        $phaseTasks = $tasks | Where-Object { $_.ProjectId -eq $project.ProjectId -and $_.TaskType -eq 'phase' }
        foreach ($phase in $phaseTasks) {
            $milestones += @{
                ProjectId = $project.ProjectId
                Name = $phase.TaskName
                Date = $phase.EndDate
                Type = 'phase'
            }
        }
    }
    
    return $milestones | Sort-Object Date
}

function Set-Milestone {
    param(
        [string]$ProjectId,
        [string]$Name,
        [DateTime]$Date,
        [string]$Type = 'custom'
    )
    
    $milestonesPath = Join-Path $ScriptDir '..\data\milestones.json'
    $milestones = @()
    
    if (Test-Path $milestonesPath) {
        $milestones = Get-Content $milestonesPath | ConvertFrom-Json
    }
    
    $milestone = @{
        ProjectId = $ProjectId
        Name = $Name
        Date = $Date.ToString('yyyy-MM-dd')
        Type = $Type
        CreatedAt = Get-Date
        Status = 'pending'
    }
    
    $milestones += $milestone
    $milestones | ConvertTo-Json -Depth 10 | Out-File $milestonesPath -Encoding UTF8
    
    Write-Host "[Timeline] 已设置里程碑：$Name ($($Date.ToString('yyyy-MM-dd')))" -ForegroundColor Green
    
    return $milestone
}

function Get-TimelineAlerts {
    param(
        [int]$DaysThreshold = 3
    )
    
    $today = Get-Date
    $alerts = @()
    
    $trackingPath = Join-Path $ScriptDir '..\data\timeline-tracking.json'
    if (Test-Path $trackingPath) {
        $tracking = Get-Content $trackingPath | ConvertFrom-Json
        
        # 逾期警报
        foreach ($item in $tracking.OverdueItems) {
            $alerts += @{
                Level = 'critical'
                Type = 'overdue'
                Message = "$($item.Name) 已逾期 $($item.DaysOverdue) 天"
                Item = $item
            }
        }
        
        # 即将到期警报
        foreach ($item in $tracking.UpcomingDeadlines) {
            if ($item.DaysRemaining -le $DaysThreshold) {
                $alerts += @{
                    Level = 'warning'
                    Type = 'upcoming'
                    Message = "$($item.Name) 将在 $($item.DaysRemaining) 天后到期"
                    Item = $item
                }
            }
        }
    }
    
    return $alerts
}
