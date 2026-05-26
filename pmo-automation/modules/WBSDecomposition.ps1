<#
.SYNOPSIS
    WBS 分解模块
.DESCRIPTION
    自动进行项目工作分解结构 (WBS) 分解，生成任务层级
#>

# 标准 WBS 模板
$WBSTemplates = @{
    'Software' = @{
        Name = '软件开发项目'
        Phases = @(
            @{ Name = '需求分析'; Duration = 5; Tasks = @('需求收集', '需求分析', '需求文档编写', '需求评审') }
            @{ Name = '系统设计'; Duration = 7; Tasks = @('架构设计', '数据库设计', '接口设计', '设计评审') }
            @{ Name = '开发实现'; Duration = 20; Tasks = @('环境搭建', '模块开发', '单元测试', '代码审查') }
            @{ Name = '测试验收'; Duration = 10; Tasks = @('集成测试', '系统测试', '用户验收测试', '缺陷修复') }
            @{ Name = '部署上线'; Duration = 3; Tasks = @('生产环境准备', '数据迁移', '系统部署', '上线验证') }
        )
    }
    'Marketing' = @{
        Name = '市场营销项目'
        Phases = @(
            @{ Name = '市场调研'; Duration = 5; Tasks = @('竞品分析', '用户调研', '市场定位') }
            @{ Name = '策略制定'; Duration = 5; Tasks = @('营销策略', '渠道规划', '预算制定') }
            @{ Name = '内容制作'; Duration = 10; Tasks = @('文案撰写', '设计素材', '视频制作') }
            @{ Name = '推广执行'; Duration = 15; Tasks = @('渠道投放', '活动执行', '数据监控') }
            @{ Name = '效果评估'; Duration = 5; Tasks = @('数据分析', '效果报告', '优化建议') }
        )
    }
    'Event' = @{
        Name = '活动组织项目'
        Phases = @(
            @{ Name = '活动策划'; Duration = 7; Tasks = @('主题确定', '方案策划', '预算编制') }
            @{ Name = '筹备执行'; Duration = 14; Tasks = @('场地预定', '供应商对接', '物料准备', '人员安排') }
            @{ Name = '活动执行'; Duration = 3; Tasks = @('现场布置', '活动进行', '现场管理') }
            @{ Name = '后续工作'; Duration = 5; Tasks = @('费用结算', '效果评估', '资料归档') }
        )
    }
    'General' = @{
        Name = '通用项目'
        Phases = @(
            @{ Name = '启动阶段'; Duration = 3; Tasks = @('项目立项', '团队组建', '启动会议') }
            @{ Name = '规划阶段'; Duration = 5; Tasks = @('范围定义', '计划制定', '风险评估') }
            @{ Name = '执行阶段'; Duration = 15; Tasks = @('任务执行', '进度跟踪', '质量管理') }
            @{ Name = '收尾阶段'; Duration = 5; Tasks = @('验收交付', '文档归档', '项目总结') }
        )
    }
}

function Generate-WBS {
    param(
        [string]$ProjectId = 'all',
        [string]$TemplateType = 'auto'
    )
    
    Write-Host "[WBS] 开始 WBS 分解..." -ForegroundColor Cyan
    
    # 加载项目数据
    $dataPath = Join-Path $ScriptDir '..\data'
    $projects = Get-Content (Join-Path $dataPath 'projects.json') | ConvertFrom-Json
    
    if ($ProjectId -ne 'all') {
        $projects = $projects | Where-Object { $_.ProjectId -eq $ProjectId }
    }
    
    $allTasks = @()
    
    foreach ($project in $projects) {
        Write-Host "`n  处理项目：$($project.ProjectName ?? $project.ProjectId)" -ForegroundColor Yellow
        
        # 自动选择模板
        if ($TemplateType -eq 'auto') {
            $TemplateType = Select-WBSTemplate -Project $project
        }
        
        $template = $WBSTemplates[$TemplateType] ?? $WBSTemplates['General']
        Write-Host "    使用模板：$($template.Name)" -ForegroundColor Gray
        
        # 生成 WBS
        $wbsTasks = Generate-WBSTasks -Project $project -Template $template
        
        foreach ($task in $wbsTasks) {
            $task | Add-Member -NotePropertyName 'ProjectId' -NotePropertyValue $project.ProjectId -Force
            $allTasks += $task
        }
        
        Write-Host "    [OK] 生成 $($wbsTasks.Count) 个任务" -ForegroundColor Green
    }
    
    # 合并现有任务
    $existingTasks = @()
    $tasksPath = Join-Path $dataPath 'tasks.json'
    if (Test-Path $tasksPath) {
        $existingTasks = Get-Content $tasksPath | ConvertFrom-Json
    }
    
    # 去重合并（基于 ProjectId + TaskId）
    $existingTasks = $existingTasks | Where-Object { 
        $key = $_.ProjectId + $_.TaskId
        $allTasks | Where-Object { ($_.ProjectId + $_.TaskId) -ne $key }
    }
    
    $allTasks = $existingTasks + $allTasks
    
    # 保存任务
    $allTasks | ConvertTo-Json -Depth 10 | Out-File $tasksPath -Encoding UTF8
    
    Write-Host "`n[OK] WBS 分解完成，共 $($allTasks.Count) 个任务" -ForegroundColor Green
    
    # 生成 WBS 报告
    Generate-WBSReport -Tasks $allTasks -Projects $projects
    
    return $allTasks
}

function Select-WBSTemplate {
    param([object]$Project)
    
    $projectName = ($project.ProjectName ?? '').ToLower()
    $projectType = ($project.Type ?? '').ToLower()
    
    if ($projectName -match '软件 | 开发 | system | app | website' -or 
        $projectType -eq 'software') {
        return 'Software'
    }
    elseif ($projectName -match '市场 | 营销 | 推广 | marketing | campaign' -or 
            $projectType -eq 'marketing') {
        return 'Marketing'
    }
    elseif ($projectName -match '活动 | 会议 | event | conference' -or 
            $projectType -eq 'event') {
        return 'Event'
    }
    
    return 'General'
}

function Generate-WBSTasks {
    param(
        [object]$Project,
        [object]$Template
    )
    
    $tasks = @()
    $startDate = Get-Date
    
    if ($project.StartDate) {
        try {
            $startDate = [DateTime]::Parse($project.StartDate)
        }
        catch {
            # 使用当前日期
        }
    }
    
    $phaseIndex = 0
    foreach ($phase in $Template.Phases) {
        $phaseId = "WBS-$($project.ProjectId)-$($phaseIndex + 1)"
        
        # 创建阶段任务
        $phaseTask = @{
            TaskId = $phaseId
            TaskName = $phase.Name
            TaskType = 'phase'
            Level = 1
            StartDate = $startDate.ToString('yyyy-MM-dd')
            EndDate = $startDate.AddDays($phase.Duration).ToString('yyyy-MM-dd')
            Duration = $phase.Duration
            Status = 'pending'
            ParentTaskId = $null
            WBSCode = ($phaseIndex + 1).ToString()
        }
        $tasks += $phaseTask
        
        # 创建子任务
        $taskIndex = 0
        foreach ($taskName in $phase.Tasks) {
            $taskStartDate = $startDate.AddDays($taskIndex * [math]::Ceiling($phase.Duration / $phase.Tasks.Count))
            $taskDuration = [math]::Ceiling($phase.Duration / $phase.Tasks.Count)
            
            $subTask = @{
                TaskId = "$phaseId-$(($taskIndex + 1).ToString('D2'))"
                TaskName = $taskName
                TaskType = 'task'
                Level = 2
                StartDate = $taskStartDate.ToString('yyyy-MM-dd')
                EndDate = $taskStartDate.AddDays($taskDuration).ToString('yyyy-MM-dd')
                Duration = $taskDuration
                Status = 'pending'
                ParentTaskId = $phaseId
                WBSCode = "$($phaseIndex + 1).$(($taskIndex + 1).ToString('D2'))"
            }
            $tasks += $subTask
            $taskIndex++
        }
        
        $startDate = $startDate.AddDays($phase.Duration)
        $phaseIndex++
    }
    
    return $tasks
}

function Generate-WBSReport {
    param(
        [array]$Tasks,
        [array]$Projects
    )
    
    $outputPath = Join-Path $ScriptDir '..\output\reports'
    if (-not (Test-Path $outputPath)) {
        New-Item -ItemType Directory -Force -Path $outputPath | Out-Null
    }
    
    $report = @"
# WBS 分解报告
生成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## 项目概览
总项目数：$($projects.Count)
总任务数：$($tasks.Count)

## 任务分解明细

"@
    
    foreach ($project in $projects) {
        $projectTasks = $tasks | Where-Object { $_.ProjectId -eq $project.ProjectId }
        
        $report += @"

### 项目：$($project.ProjectName ?? $project.ProjectId)

| WBS 编码 | 任务名称 | 类型 | 开始日期 | 结束日期 | 工期 (天) | 状态 |
|---------|---------|------|---------|---------|----------|------|
"@
        
        foreach ($task in $projectTasks | Sort-Object WBSCode) {
            $report += "| $($task.WBSCode) | $($task.TaskName) | $($task.TaskType) | $($task.StartDate) | $($task.EndDate) | $($task.Duration) | $($task.Status) |`n"
        }
    }
    
    $reportFile = Join-Path $outputPath "wbs-report-$(Get-Date -Format 'yyyyMMdd').md"
    $report | Out-File $reportFile -Encoding UTF8
    
    Write-Host "  [OK] WBS 报告已保存：$reportFile" -ForegroundColor Green
}

function Get-WBSGanttData {
    param([string]$ProjectId)
    
    $tasksPath = Join-Path $ScriptDir '..\data\tasks.json'
    if (-not (Test-Path $tasksPath)) {
        return @()
    }
    
    $tasks = Get-Content $tasksPath | ConvertFrom-Json
    
    if ($ProjectId) {
        $tasks = $tasks | Where-Object { $_.ProjectId -eq $ProjectId }
    }
    
    return $tasks | Sort-Object StartDate
}
