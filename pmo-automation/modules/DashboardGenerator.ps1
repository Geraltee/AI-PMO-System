<#
.SYNOPSIS
    Dashboard 生成器模块
.DESCRIPTION
    生成 HTML 可视化 Dashboard，展示项目进度、资源分配、时间节点等
#>

function Generate-Dashboard {
    param(
        [string]$OutputPath = '.\output\dashboards',
        [string]$TemplateName = 'dashboard.html'
    )
    
    Write-Host "[Dashboard] 生成 Dashboard..." -ForegroundColor Cyan
    
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null
    }
    
    # 加载数据
    $dataPath = Join-Path $ScriptDir '..\data'
    $employees = @()
    $projects = @()
    $tasks = @()
    
    if (Test-Path (Join-Path $dataPath 'employees.json')) {
        $employees = Get-Content (Join-Path $dataPath 'employees.json') | ConvertFrom-Json
    }
    if (Test-Path (Join-Path $dataPath 'projects.json')) {
        $projects = Get-Content (Join-Path $dataPath 'projects.json') | ConvertFrom-Json
    }
    if (Test-Path (Join-Path $dataPath 'tasks.json')) {
        $tasks = Get-Content (Join-Path $dataPath 'tasks.json') | ConvertFrom-Json
    }
    
    # 生成 Dashboard 数据
    $dashboardData = @{
        GeneratedAt = Get-Date
        Summary = @{
            TotalProjects = $projects.Count
            TotalEmployees = $employees.Count
            TotalTasks = $tasks.Count
            ActiveProjects = ($projects | Where-Object { $_.Status -eq 'active' }).Count
            OverdueTasks = ($tasks | Where-Object { $_.Status -ne 'completed' -and $_.DueDate -lt (Get-Date) }).Count
        }
        Projects = $projects
        Employees = $employees
        Tasks = $tasks
        Timeline = Generate-TimelineData -Projects $projects -Tasks $tasks
        ResourceAllocation = Generate-ResourceAllocation -Employees $employees -Tasks $tasks
    }
    
    # 生成 HTML
    $htmlContent = Generate-DashboardHTML -Data $dashboardData
    
    # 保存文件
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $outputFile = Join-Path $OutputPath "dashboard-$timestamp.html"
    $htmlContent | Out-File $outputFile -Encoding UTF8
    
    # 同时生成一个 index.html 作为最新 Dashboard
    $htmlContent | Out-File (Join-Path $OutputPath 'index.html') -Encoding UTF8
    
    Write-Host "[OK] Dashboard 已生成：$outputFile" -ForegroundColor Green
    Write-Host "       访问：file:///$outputFile" -ForegroundColor Cyan
    
    return $outputFile
}

function Generate-TimelineData {
    param(
        [array]$Projects,
        [array]$Tasks
    )
    
    $timeline = @()
    $startDate = Get-Date
    $endDate = $startDate.AddMonths(3)
    
    foreach ($project in $Projects) {
        $timeline += @{
            Type = 'project'
            Name = $project.ProjectName ?? $project.ProjectId
            Start = $project.StartDate ?? $startDate
            End = $project.EndDate ?? $endDate
            Status = $project.Status ?? 'planning'
        }
    }
    
    foreach ($task in $Tasks) {
        $timeline += @{
            Type = 'task'
            Name = $task.Name ?? $task.Title
            Start = $task.StartDate ?? $startDate
            End = $task.DueDate ?? $endDate
            Status = $task.Status ?? 'pending'
            ProjectId = $task.ProjectId
        }
    }
    
    return $timeline
}

function Generate-ResourceAllocation {
    param(
        [array]$Employees,
        [array]$Tasks
    )
    
    $allocation = @{}
    
    foreach ($emp in $Employees) {
        $empName = $emp.Name ?? $emp.EmployeeId
        $assignedTasks = $tasks | Where-Object { $_.AssignedTo -eq $empName -or $_.AssignedTo -eq $emp.EmployeeId }
        
        $allocation[$empName] = @{
            Name = $empName
            Department = $emp.Department ?? '未分配'
            TotalTasks = $assignedTasks.Count
            CompletedTasks = ($assignedTasks | Where-Object { $_.Status -eq 'completed' }).Count
            PendingTasks = ($assignedTasks | Where-Object { $_.Status -ne 'completed' }).Count
            Skills = $emp.Skills ?? @()
            Availability = $emp.Availability ?? '未知'
        }
    }
    
    return $allocation
}

function Generate-DashboardHTML {
    param([hashtable]$Data)
    
    $summary = $Data.Summary
    $projects = $Data.Projects
    $employees = $Data.Employees
    $tasks = $Data.Tasks
    
    # 生成项目表格行
    $projectRows = ""
    foreach ($proj in $projects) {
        $statusClass = switch ($proj.Status) {
            'active' { 'status-active' }
            'completed' { 'status-completed' }
            'delayed' { 'status-delayed' }
            default { 'status-pending' }
        }
        $projectRows += @"
            <tr>
                <td>$($proj.ProjectName ?? $proj.ProjectId)</td>
                <td><span class="status-badge $statusClass">$($proj.Status ?? 'planning')</span></td>
                <td>$($proj.StartDate ?? 'TBD')</td>
                <td>$($proj.EndDate ?? 'TBD')</td>
                <td>$($proj.Priority ?? 'medium')</td>
            </tr>
"@
    }
    
    # 生成任务表格行
    $taskRows = ""
    foreach ($task in $tasks | Select-Object -First 20) {
        $taskRows += @"
            <tr>
                <td>$($task.Name ?? $task.Title)</td>
                <td>$($task.ProjectId ?? '-')</td>
                <td>$($task.AssignedTo ?? '未分配')</td>
                <td>$($task.DueDate ?? 'TBD')</td>
                <td><span class="status-badge status-$($task.Status ?? 'pending')">$($task.Status ?? 'pending')</span></td>
            </tr>
"@
    }
    
    # 生成资源分配图表数据
    $resourceLabels = ($employees | ForEach-Object { $_.Name ?? $_.EmployeeId }) -join "','"
    $resourceData = ($employees | ForEach-Object { 
        $empTasks = $tasks | Where-Object { $_.AssignedTo -eq ($_.Name ?? $_.EmployeeId) }
        $empTasks.Count
    }) -join ','
    
    $html = @"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PMO Dashboard - $(Get-Date -Format 'yyyy-MM-dd HH:mm')</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', 'Microsoft YaHei', sans-serif; 
            background: #f5f7fa; 
            padding: 20px;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        .header h1 { font-size: 2em; margin-bottom: 10px; }
        .header p { opacity: 0.9; }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .stat-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
        }
        .stat-card h3 { color: #667eea; font-size: 2.5em; margin-bottom: 5px; }
        .stat-card p { color: #666; font-size: 0.9em; }
        
        .section {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        .section h2 { 
            color: #333; 
            margin-bottom: 20px; 
            padding-bottom: 10px;
            border-bottom: 2px solid #667eea;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        th {
            background: #f8f9fa;
            color: #333;
            font-weight: 600;
        }
        tr:hover { background: #f8f9fa; }
        
        .status-badge {
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: 500;
        }
        .status-active { background: #d4edda; color: #155724; }
        .status-completed { background: #cce5ff; color: #004085; }
        .status-delayed { background: #f8d7da; color: #721c24; }
        .status-pending { background: #fff3cd; color: #856404; }
        
        .chart-container {
            position: relative;
            height: 300px;
            margin: 20px 0;
        }
        
        .grid-2 {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 20px;
        }
        
        .footer {
            text-align: center;
            padding: 20px;
            color: #666;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>📊 PMO 项目管理 Dashboard</h1>
        <p>生成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    
    <div class="stats-grid">
        <div class="stat-card">
            <h3>$($summary.TotalProjects)</h3>
            <p>总项目数</p>
        </div>
        <div class="stat-card">
            <h3>$($summary.ActiveProjects)</h3>
            <p>进行中项目</p>
        </div>
        <div class="stat-card">
            <h3>$($summary.TotalEmployees)</h3>
            <p>团队成员</p>
        </div>
        <div class="stat-card">
            <h3>$($summary.TotalTasks)</h3>
            <p>总任务数</p>
        </div>
        <div class="stat-card">
            <h3 style="color: #dc3545;">$($summary.OverdueTasks)</h3>
            <p>逾期任务</p>
        </div>
    </div>
    
    <div class="grid-2">
        <div class="section">
            <h2>📈 资源分配</h2>
            <div class="chart-container">
                <canvas id="resourceChart"></canvas>
            </div>
        </div>
        <div class="section">
            <h2>🎯 项目状态分布</h2>
            <div class="chart-container">
                <canvas id="projectStatusChart"></canvas>
            </div>
        </div>
    </div>
    
    <div class="section">
        <h2>📋 项目列表</h2>
        <table>
            <thead>
                <tr>
                    <th>项目名称</th>
                    <th>状态</th>
                    <th>开始日期</th>
                    <th>结束日期</th>
                    <th>优先级</th>
                </tr>
            </thead>
            <tbody>
                $projectRows
            </tbody>
        </table>
    </div>
    
    <div class="section">
        <h2>✅ 任务列表 (最近 20 条)</h2>
        <table>
            <thead>
                <tr>
                    <th>任务名称</th>
                    <th>所属项目</th>
                    <th>负责人</th>
                    <th>截止日期</th>
                    <th>状态</th>
                </tr>
            </thead>
            <tbody>
                $taskRows
            </tbody>
        </table>
    </div>
    
    <div class="footer">
        <p>PMO 自动化管理系统 | 最后更新：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    
    <script>
        // 资源分配图表
        const resourceCtx = document.getElementById('resourceChart').getContext('2d');
        new Chart(resourceCtx, {
            type: 'bar',
            data: {
                labels: ['$resourceLabels'.split(',')],
                datasets: [{
                    label: '分配任务数',
                    data: [$resourceData],
                    backgroundColor: 'rgba(102, 126, 234, 0.7)',
                    borderColor: 'rgba(102, 126, 234, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: { beginAtZero: true }
                }
            }
        });
        
        // 项目状态分布
        const statusCtx = document.getElementById('projectStatusChart').getContext('2d');
        new Chart(statusCtx, {
            type: 'doughnut',
            data: {
                labels: ['进行中', '已完成', '已延期', '计划中'],
                datasets: [{
                    data: [
                        $($projects | Where-Object { $_.Status -eq 'active' } | Measure-Object | Select-Object -ExpandProperty Count),
                        $($projects | Where-Object { $_.Status -eq 'completed' } | Measure-Object | Select-Object -ExpandProperty Count),
                        $($projects | Where-Object { $_.Status -eq 'delayed' } | Measure-Object | Select-Object -ExpandProperty Count),
                        $($projects | Where-Object { $_.Status -eq 'planning' -or -not $_.Status } | Measure-Object | Select-Object -ExpandProperty Count)
                    ],
                    backgroundColor: [
                        'rgba(40, 167, 69, 0.7)',
                        'rgba(0, 123, 255, 0.7)',
                        'rgba(220, 53, 69, 0.7)',
                        'rgba(255, 193, 7, 0.7)'
                    ]
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false
            }
        });
    </script>
</body>
</html>
"@
    
    return $html
}
