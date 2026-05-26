#!/usr/bin/env pwsh
<#
.SYNOPSIS
    PMO 自动化管理系统主入口
.DESCRIPTION
    项目管理办公室自动化管理系统，集成文档解析、Dashboard 生成、角色分配、
    WBS 分解、SOP 生成、时间追踪、周会总结和邮件提醒功能。
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('Init', 'Import', 'Generate-Dashboard', 'Assign-Roles', 'Generate-WBS', 
                 'Generate-SOP', 'Track-Timeline', 'Weekly-Summary', 'Send-Reminders', 'Status', 'Help')]
    [string]$Action = 'Status',
    
    [Parameter(Mandatory = $false)]
    [string]$Path,
    
    [Parameter(Mandatory = $false)]
    [string]$ProjectId,
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# 设置脚本目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesDir = Join-Path $ScriptDir 'modules'
$ConfigDir = Join-Path $ScriptDir 'config'
$DataDir = Join-Path $ScriptDir 'data'
$OutputDir = Join-Path $ScriptDir 'output'

# 导入配置
$SettingsPath = Join-Path $ConfigDir 'settings.json'
if (Test-Path $SettingsPath) {
    $Settings = Get-Content $SettingsPath | ConvertFrom-Json
} else {
    $Settings = @{
        ProjectRoot = $ScriptDir
        OutputPath = $OutputDir
        DataPath = $DataDir
        EmailEnabled = $true
        DashboardRefreshInterval = 3600
    }
}

# 导入所有模块
$moduleFiles = @(
    'DocumentParser.ps1',
    'DashboardGenerator.ps1', 
    'RoleAssignment.ps1',
    'WBSDecomposition.ps1',
    'SOPGenerator.ps1',
    'TimelineTracker.ps1',
    'WeeklySummary.ps1',
    'EmailNotifier.ps1'
)

foreach ($module in $moduleFiles) {
    $modulePath = Join-Path $ModulesDir $module
    if (Test-Path $modulePath) {
        . $modulePath
        Write-Host "[OK] 已加载模块：$module" -ForegroundColor Green
    } else {
        Write-Host "[WARN] 模块不存在：$module" -ForegroundColor Yellow
    }
}

# 主函数
function Invoke-PMOAction {
    param([string]$Action)
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  PMO 自动化管理系统 - $Action" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    switch ($Action) {
        'Init' {
            Initialize-System
        }
        'Import' {
            if ($Path) {
                Import-ProjectDocuments -Path $Path
            } else {
                Write-Host "[ERROR] 请指定文档路径：-Path <路径>" -ForegroundColor Red
            }
        }
        'Generate-Dashboard' {
            Generate-Dashboard -OutputPath (Join-Path $OutputDir 'dashboards')
        }
        'Assign-Roles' {
            if ($ProjectId) {
                Assign-ProjectRoles -ProjectId $ProjectId
            } else {
                Write-Host "[INFO] 未指定项目 ID，将处理所有项目" -ForegroundColor Yellow
                Assign-ProjectRoles -ProjectId 'all'
            }
        }
        'Generate-WBS' {
            if ($ProjectId) {
                Generate-WBS -ProjectId $ProjectId
            } else {
                Generate-WBS -ProjectId 'all'
            }
        }
        'Generate-SOP' {
            Generate-SOPs -ProjectId ($ProjectId ?? 'all')
        }
        'Track-Timeline' {
            Track-ProjectTimelines
        }
        'Weekly-Summary' {
            Generate-WeeklySummary
        }
        'Send-Reminders' {
            Send-ProjectReminders
        }
        'Status' {
            Show-SystemStatus
        }
        'Help' {
            Show-Help
        }
    }
}

# 系统初始化
function Initialize-System {
    Write-Host "正在初始化 PMO 系统..." -ForegroundColor Green
    
    # 创建必要的目录
    $dirs = @(
        (Join-Path $OutputDir 'dashboards'),
        (Join-Path $OutputDir 'reports'),
        (Join-Path $OutputDir 'sops'),
        (Join-Path $DataDir 'cache')
    )
    
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
            Write-Host "  [OK] 创建目录：$dir" -ForegroundColor Green
        }
    }
    
    # 初始化数据文件
    if (-not (Test-Path (Join-Path $DataDir 'employees.json'))) {
        @() | ConvertTo-Json | Out-File (Join-Path $DataDir 'employees.json') -Encoding UTF8
        Write-Host "  [OK] 创建员工数据文件" -ForegroundColor Green
    }
    
    if (-not (Test-Path (Join-Path $DataDir 'projects.json'))) {
        @() | ConvertTo-Json | Out-File (Join-Path $DataDir 'projects.json') -Encoding UTF8
        Write-Host "  [OK] 创建项目数据文件" -ForegroundColor Green
    }
    
    if (-not (Test-Path (Join-Path $DataDir 'tasks.json'))) {
        @() | ConvertTo-Json | Out-File (Join-Path $DataDir 'tasks.json') -Encoding UTF8
        Write-Host "  [OK] 创建任务数据文件" -ForegroundColor Green
    }
    
    Write-Host "`n系统初始化完成！" -ForegroundColor Green
    Write-Host "请导入项目文档开始使用。" -ForegroundColor Cyan
}

# 显示系统状态
function Show-SystemStatus {
    Write-Host "PMO 自动化管理系统状态`n" -ForegroundColor Cyan
    
    # 检查模块
    Write-Host "已加载模块:" -ForegroundColor Yellow
    $moduleCount = 0
    foreach ($module in $moduleFiles) {
        $modulePath = Join-Path $ModulesDir $module
        if (Test-Path $modulePath) {
            Write-Host "  [✓] $module" -ForegroundColor Green
            $moduleCount++
        } else {
            Write-Host "  [✗] $module" -ForegroundColor Red
        }
    }
    Write-Host "  总计：$moduleCount / $($moduleFiles.Count) 模块`n"
    
    # 检查数据
    Write-Host "数据文件:" -ForegroundColor Yellow
    $dataFiles = @('employees.json', 'projects.json', 'tasks.json')
    foreach ($file in $dataFiles) {
        $filePath = Join-Path $DataDir $file
        if (Test-Path $filePath) {
            $content = Get-Content $filePath | ConvertFrom-Json
            $count = if ($content -is [array]) { $content.Count } else { 0 }
            Write-Host "  [✓] $file ($count 条记录)" -ForegroundColor Green
        } else {
            Write-Host "  [✗] $file (不存在)" -ForegroundColor Red
        }
    }
    
    # 检查输出
    Write-Host "`n输出目录:" -ForegroundColor Yellow
    $outputDirs = @('dashboards', 'reports', 'sops')
    foreach ($dir in $outputDirs) {
        $dirPath = Join-Path $OutputDir $dir
        if (Test-Path $dirPath) {
            $fileCount = (Get-ChildItem $dirPath -File).Count
            Write-Host "  [✓] $dir ($fileCount 个文件)" -ForegroundColor Green
        } else {
            Write-Host "  [✗] $dir (不存在)" -ForegroundColor Red
        }
    }
}

# 显示帮助
function Show-Help {
    Write-Host @"
PMO 自动化管理系统 - 使用帮助

用法：.\Main.ps1 -Action <操作> [参数]

可用操作:
  Init              初始化系统
  Import            导入项目文档 (-Path 指定路径)
  Generate-Dashboard 生成 HTML Dashboard
  Assign-Roles      分配项目角色 (-ProjectId 可选)
  Generate-WBS      生成 WBS 分解 (-ProjectId 可选)
  Generate-SOP      生成 SOP 文档 (-ProjectId 可选)
  Track-Timeline    追踪项目时间节点
  Weekly-Summary    生成周会总结
  Send-Reminders    发送项目提醒
  Status            显示系统状态
  Help              显示此帮助信息

示例:
  .\Main.ps1 -Action Init
  .\Main.ps1 -Action Import -Path "C:\项目文档"
  .\Main.ps1 -Action Generate-Dashboard
  .\Main.ps1 -Action Assign-Roles -ProjectId "PRJ-2024-001"

OpenClaw Cron 集成:
  系统支持通过 OpenClaw cron 定时执行任务
  配置文件：config/cron-jobs.json

"@ -ForegroundColor White
}

# 执行主操作
Invoke-PMOAction -Action $Action
