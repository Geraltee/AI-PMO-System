<#
.SYNOPSIS
    自动角色分配引擎
.DESCRIPTION
    根据员工技能、可用性和项目需求自动分配角色
#>

# 预定义角色类型
$RoleTypes = @{
    'ProjectManager' = @{
        Name = '项目经理'
        RequiredSkills = @('项目管理', '沟通协调', '风险控制')
        Priority = 1
    }
    'TechLead' = @{
        Name = '技术负责人'
        RequiredSkills = @('架构设计', '技术决策', '代码审查')
        Priority = 2
    }
    'Developer' = @{
        Name = '开发工程师'
        RequiredSkills = @('编程', '软件开发')
        Priority = 3
    }
    'Designer' = @{
        Name = '设计师'
        RequiredSkills = @('UI 设计', 'UX 设计', '原型设计')
        Priority = 3
    }
    'Tester' = @{
        Name = '测试工程师'
        RequiredSkills = @('测试', '质量保证')
        Priority = 3
    }
    'BusinessAnalyst' = @{
        Name = '业务分析师'
        RequiredSkills = @('需求分析', '业务流程')
        Priority = 2
    }
}

function Assign-ProjectRoles {
    param(
        [string]$ProjectId = 'all'
    )
    
    Write-Host "[RoleAssignment] 开始角色分配..." -ForegroundColor Cyan
    
    # 加载数据
    $dataPath = Join-Path $ScriptDir '..\data'
    $employees = Get-Content (Join-Path $dataPath 'employees.json') | ConvertFrom-Json
    $projects = Get-Content (Join-Path $dataPath 'projects.json') | ConvertFrom-Json
    
    if ($ProjectId -ne 'all') {
        $projects = $projects | Where-Object { $_.ProjectId -eq $ProjectId }
    }
    
    $assignments = @()
    
    foreach ($project in $projects) {
        Write-Host "`n  处理项目：$($project.ProjectName ?? $project.ProjectId)" -ForegroundColor Yellow
        
        $projectId = $project.ProjectId
        $projectRoles = $project.RequiredRoles ?? @('ProjectManager', 'Developer', 'Tester')
        
        foreach ($roleType in $projectRoles) {
            $roleInfo = $RoleTypes[$roleType]
            if (-not $roleInfo) {
                Write-Host "    [WARN] 未知角色类型：$roleType" -ForegroundColor Yellow
                continue
            }
            
            # 查找合适的员工
            $candidate = Find-BestCandidate -Employees $employees -RoleType $roleType -ProjectId $projectId
            
            if ($candidate) {
                $assignment = @{
                    ProjectId = $projectId
                    ProjectName = $project.ProjectName ?? $projectId
                    RoleType = $roleType
                    RoleName = $roleInfo.Name
                    EmployeeId = $candidate.EmployeeId ?? $candidate.Name
                    EmployeeName = $candidate.Name
                    AssignedDate = Get-Date
                    Skills = $candidate.Skills
                    MatchScore = $candidate.MatchScore
                }
                
                $assignments += $assignment
                Write-Host "    [OK] $($roleInfo.Name) -> $($candidate.Name) (匹配度：$($candidate.MatchScore)%)" -ForegroundColor Green
            } else {
                Write-Host "    [WARN] 未找到合适的 $($roleInfo.Name)" -ForegroundColor Yellow
            }
        }
    }
    
    # 保存分配结果
    if ($assignments.Count -gt 0) {
        $outputPath = Join-Path $dataPath 'role-assignments.json'
        $existingAssignments = @()
        if (Test-Path $outputPath) {
            $existingAssignments = Get-Content $outputPath | ConvertFrom-Json
        }
        
        # 合并新分配（避免重复）
        $existingAssignments = $existingAssignments | Where-Object { 
            $new = $_.ProjectId + $_.RoleType
            $assignments | Where-Object { ($_.ProjectId + $_.RoleType) -ne $new }
        }
        
        $existingAssignments += $assignments
        $existingAssignments | ConvertTo-Json -Depth 10 | Out-File $outputPath -Encoding UTF8
        
        Write-Host "`n[OK] 角色分配完成，共 $($assignments.Count) 个分配" -ForegroundColor Green
    }
    
    return $assignments
}

function Find-BestCandidate {
    param(
        [array]$Employees,
        [string]$RoleType,
        [string]$ProjectId
    )
    
    $roleInfo = $RoleTypes[$roleType]
    $requiredSkills = $roleInfo.RequiredSkills
    
    # 排除已在此项目中分配角色的员工
    $assignmentsPath = Join-Path $ScriptDir '..\data\role-assignments.json'
    $existingAssignments = @()
    if (Test-Path $assignmentsPath) {
        $existingAssignments = Get-Content $assignmentsPath | ConvertFrom-Json
    }
    
    $assignedEmployees = $existingAssignments | 
        Where-Object { $_.ProjectId -eq $ProjectId } | 
        Select-Object -ExpandProperty EmployeeId -Unique
    
    $candidates = $employees | Where-Object { 
        $_.EmployeeId -notin $assignedEmployees -and 
        $_.Name -notin $assignedEmployees 
    }
    
    $bestCandidate = $null
    $bestScore = 0
    
    foreach ($candidate in $candidates) {
        $score = Calculate-MatchScore -Employee $candidate -RequiredSkills $requiredSkills
        
        if ($score -gt $bestScore) {
            $bestScore = $score
            $bestCandidate = $candidate
            $bestCandidate | Add-Member -NotePropertyName 'MatchScore' -NotePropertyValue $score -Force
        }
    }
    
    # 只返回匹配度超过 30% 的候选人
    if ($bestScore -ge 30) {
        return $bestCandidate
    }
    
    return $null
}

function Calculate-MatchScore {
    param(
        [object]$Employee,
        [array]$RequiredSkills
    )
    
    $employeeSkills = $Employee.Skills ?? @()
    if ($employeeSkills -is [string]) {
        $employeeSkills = $employeeSkills -split '[,;]' | ForEach-Object { $_.Trim() }
    }
    
    $matchCount = 0
    foreach ($reqSkill in $RequiredSkills) {
        foreach ($empSkill in $employeeSkills) {
            if ($empSkill.ToLower().Contains($reqSkill.ToLower()) -or 
                $reqSkill.ToLower().Contains($empSkill.ToLower())) {
                $matchCount++
                break
            }
        }
    }
    
    if ($RequiredSkills.Count -eq 0) { return 0 }
    
    $score = [math]::Round(($matchCount / $RequiredSkills.Count) * 100)
    return $score
}

function Get-RoleAssignmentReport {
    param([string]$ProjectId)
    
    $assignmentsPath = Join-Path $ScriptDir '..\data\role-assignments.json'
    if (-not (Test-Path $assignmentsPath)) {
        Write-Host "[INFO] 暂无角色分配记录" -ForegroundColor Yellow
        return @()
    }
    
    $assignments = Get-Content $assignmentsPath | ConvertFrom-Json
    
    if ($ProjectId) {
        $assignments = $assignments | Where-Object { $_.ProjectId -eq $ProjectId }
    }
    
    return $assignments
}
