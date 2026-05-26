<#
.SYNOPSIS
    文档解析模块
.DESCRIPTION
    解析员工信息、项目背景等文档，提取结构化数据
#>

# 员工信息解析
function Parse-EmployeeDocument {
    param(
        [string]$FilePath,
        [string]$Format = 'auto'  # auto, excel, csv, json
    )
    
    Write-Host "[DocumentParser] 解析员工文档：$FilePath" -ForegroundColor Cyan
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "[ERROR] 文件不存在：$FilePath" -ForegroundColor Red
        return $null
    }
    
    $extension = (Get-Item $FilePath).Extension.ToLower()
    
    try {
        $employees = switch ($extension) {
            '.xlsx' { Parse-ExcelEmployees -Path $FilePath }
            '.csv' { Parse-CSVEmployees -Path $FilePath }
            '.json' { Get-Content $FilePath | ConvertFrom-Json }
            '.txt' { Parse-TextEmployees -Path $FilePath }
            default { 
                Write-Host "[WARN] 未知格式：$extension，尝试通用解析" -ForegroundColor Yellow
                Parse-GenericDocument -Path $FilePath -Type 'employee'
            }
        }
        
        # 保存到数据目录
        $outputPath = Join-Path $ScriptDir '..\data\employees.json'
        $employees | ConvertTo-Json -Depth 10 | Out-File $outputPath -Encoding UTF8
        Write-Host "[OK] 已解析 $($employees.Count) 名员工信息" -ForegroundColor Green
        
        return $employees
    }
    catch {
        Write-Host "[ERROR] 解析失败：$_" -ForegroundColor Red
        return $null
    }
}

function Parse-ExcelEmployees {
    param([string]$Path)
    # 需要 Import-Excel 模块或使用 COM
    # 简化版本：假设导出为 CSV
    $csvPath = $Path -replace '\.xlsx$', '.csv'
    if (Test-Path $csvPath) {
        return Import-Csv $csvPath
    }
    throw "需要安装 Import-Excel 模块或导出为 CSV"
}

function Parse-CSVEmployees {
    param([string]$Path)
    return Import-Csv $Path -Encoding UTF8
}

function Parse-TextEmployees {
    param([string]$Path)
    $content = Get-Content $Path -Encoding UTF8
    $employees = @()
    
    # 简单的文本解析逻辑（假设特定格式）
    $currentEmployee = @{}
    foreach ($line in $content) {
        if ($line -match '^姓名 [::]\s*(.+)') {
            if ($currentEmployee.Name) {
                $employees += $currentEmployee
            }
            $currentEmployee = @{ Name = $Matches.1 }
        }
        elseif ($line -match '^技能 [::]\s*(.+)') {
            $currentEmployee.Skills = $Matches.1 -split '[,;]' | ForEach-Object { $_.Trim() }
        }
        elseif ($line -match '^部门 [::]\s*(.+)') {
            $currentEmployee.Department = $Matches.1
        }
        elseif ($line -match '^可用时间 [::]\s*(.+)') {
            $currentEmployee.Availability = $Matches.1
        }
    }
    
    if ($currentEmployee.Name) {
        $employees += $currentEmployee
    }
    
    return $employees
}

# 项目文档解析
function Parse-ProjectDocument {
    param(
        [string]$FilePath,
        [string]$Type = 'background'  # background, requirements, spec
    )
    
    Write-Host "[DocumentParser] 解析项目文档：$FilePath (类型：$Type)" -ForegroundColor Cyan
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "[ERROR] 文件不存在：$FilePath" -ForegroundColor Red
        return $null
    }
    
    try {
        $content = Get-Content $FilePath -Encoding UTF8 -Raw
        $project = Parse-ProjectContent -Content $content -Type $Type
        
        # 加载现有项目数据
        $projectsPath = Join-Path $ScriptDir '..\data\projects.json'
        $existingProjects = @()
        if (Test-Path $projectsPath) {
            $existingProjects = Get-Content $projectsPath | ConvertFrom-Json
        }
        
        # 添加或更新项目
        $projectId = $project.ProjectId ?? ("PRJ-" + (Get-Date).ToString("yyyy-MM-dd") + "-" + (Get-Random -Maximum 999))
        $project | Add-Member -NotePropertyName 'ProjectId' -NotePropertyValue $projectId -Force
        $project | Add-Member -NotePropertyName 'ImportDate' -NotePropertyValue (Get-Date) -Force
        
        $existingProjects += $project
        
        # 保存
        $existingProjects | ConvertTo-Json -Depth 10 | Out-File $projectsPath -Encoding UTF8
        Write-Host "[OK] 项目文档解析完成，ID: $projectId" -ForegroundColor Green
        
        return $project
    }
    catch {
        Write-Host "[ERROR] 解析失败：$_" -ForegroundColor Red
        return $null
    }
}

function Parse-ProjectContent {
    param(
        [string]$Content,
        [string]$Type
    )
    
    $project = @{
        Type = $Type
        RawContent = $Content
    }
    
    # 提取常见字段
    if ($Content -match '项目名称 [::]\s*(.+)') { $project.ProjectName = $Matches.1 }
    if ($Content -match '项目目标 [::]\s*(.+)') { $project.Objectives = $Matches.1 }
    if ($Content -match '项目范围 [::]\s*(.+)') { $project.Scope = $Matches.1 }
    if ($Content -match '开始日期 [::]\s*(.+)') { $project.StartDate = $Matches.1 }
    if ($Content -match '结束日期 [::]\s*(.+)') { $project.EndDate = $Matches.1 }
    if ($Content -match '预算 [::]\s*(.+)') { $project.Budget = $Matches.1 }
    if ($Content -match '优先级 [::]\s*(.+)') { $project.Priority = $Matches.1 }
    if ($Content -match '干系人 [::]\s*(.+)') { $project.Stakeholders = $Matches.1 -split '[,;]' | ForEach-Object { $_.Trim() } }
    
    # 提取交付物
    $deliverables = @()
    if ($Content -match '(?s)交付物 [::](.+?)(?=项目 | 时间 | 备注|$)') {
        $deliverablesText = $Matches.1
        $deliverables = $deliverablesText -split "`n" | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() -replace '^[•\-\*]\s*', '' }
    }
    $project.Deliverables = $deliverables
    
    # 提取约束条件
    $constraints = @()
    if ($Content -match '(?s)约束条件 [::](.+?)(?=项目 | 时间 | 备注|$)') {
        $constraintsText = $Matches.1
        $constraints = $constraintsText -split "`n" | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() -replace '^[•\-\*]\s*', '' }
    }
    $project.Constraints = $constraints
    
    return $project
}

# 通用文档解析
function Parse-GenericDocument {
    param(
        [string]$Path,
        [string]$Type = 'unknown'
    )
    
    $content = Get-Content $Path -Encoding UTF8 -Raw
    
    return @{
        SourceFile = $Path
        Type = $Type
        Content = $content
        ParsedDate = Get-Date
    }
}

# 批量导入文档
function Import-ProjectDocuments {
    param([string]$Path)
    
    Write-Host "`n[DocumentParser] 开始批量导入文档..." -ForegroundColor Cyan
    Write-Host "源路径：$Path`n" -ForegroundColor Gray
    
    if (-not (Test-Path $Path)) {
        Write-Host "[ERROR] 路径不存在" -ForegroundColor Red
        return
    }
    
    $files = Get-ChildItem -Path $Path -File -Recurse
    $stats = @{ Employees = 0; Projects = 0; Others = 0 }
    
    foreach ($file in $files) {
        $fileName = $file.Name.ToLower()
        
        if ($fileName -match '员工 | 人员 | team | employee') {
            $result = Parse-EmployeeDocument -FilePath $file.FullName
            if ($result) { $stats.Employees++ }
        }
        elseif ($fileName -match '项目 | 背景 | 需求 | project | requirement') {
            $type = if ($fileName -match '需求') { 'requirements' } else { 'background' }
            $result = Parse-ProjectDocument -FilePath $file.FullName -Type $type
            if ($result) { $stats.Projects++ }
        }
        else {
            $stats.Others++
        }
    }
    
    Write-Host "`n[DocumentParser] 导入完成!" -ForegroundColor Green
    Write-Host "  员工文档：$($stats.Employees)" -ForegroundColor Cyan
    Write-Host "  项目文档：$($stats.Projects)" -ForegroundColor Cyan
    Write-Host "  其他文档：$($stats.Others)" -ForegroundColor Gray
}
