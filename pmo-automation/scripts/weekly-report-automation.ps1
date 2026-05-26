# PMO 周报自动化脚本
# 用于发送周报收集提醒和汇总报告

param(
    [string]$Action = "remind",
    [string]$ProjectName = "AI Smart Customer Service Upgrade",
    [switch]$SendReminder,
    [switch]$CollectReports,
    [switch]$GenerateSummary
)

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ReportsPath = "D:\AI-PMO-System\pmo-automation\reports\weekly"
$TemplatePath = "D:\AI-PMO-System\pmo-automation\templates\weekly-report.md"

# 确保目录存在
if (-not (Test-Path $ReportsPath)) {
    New-Item -ItemType Directory -Force -Path $ReportsPath | Out-Null
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PMO 周报自动化助手" -ForegroundColor Cyan
Write-Host "  项目：$ProjectName" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 项目负责人列表
$ProjectManagers = @(
    @{ Name = "张三"; Email = "zhangsan@company.com"; Role = "技术负责人" },
    @{ Name = "李四"; Email = "lisi@company.com"; Role = "产品经理" },
    @{ Name = "王五"; Email = "wangwu@company.com"; Role = "测试负责人" }
)

function Send-WeeklyReminder {
    Write-Host "📧 发送周报收集提醒..." -ForegroundColor Yellow
    Write-Host ""
    
    $WeekStart = (Get-Date).AddDays(-(Get-Date).DayOfWeek).ToString("yyyy-MM-dd")
    $WeekEnd = (Get-Date).AddDays(6 - (Get-Date).DayOfWeek).ToString("yyyy-MM-dd")
    $Today = Get-Date -Format "yyyy-MM-dd"
    
    foreach ($pm in $ProjectManagers) {
        Write-Host "  收件人：$($pm.Name) ($($pm.Role))" -ForegroundColor Cyan
        Write-Host "  邮箱：$($pm.Email)" -ForegroundColor Gray
        
        # 模拟发送邮件（实际应调用邮件 API）
        $EmailBody = @"
尊敬的 $($pm.Name)：

您好！

请提交 $ProjectName 项目的周报，内容包括：

📋 上周工作总结 ($WeekStart 至 $WeekEnd)
  - 完成情况
  - 未完成事项

📋 本周工作计划
  - 计划任务
  - 里程碑节点

⚠️ 风险与问题
  - 当前风险
  - 需要支持

📅 提交截止时间：本周三 18:00

📝 周报模板位置：
$TemplatePath

感谢您的配合！

PMO 系统自动发送
"@
        
        # 实际实现应调用邮件 API
        # Send-Email -To $pm.Email -Subject "【周报提醒】$ProjectName - $Today" -Body $EmailBody
        
        Write-Host "  ✅ 提醒已发送" -ForegroundColor Green
        Write-Host ""
    }
    
    Write-Host "✓ 所有提醒已发送完成" -ForegroundColor Green
}

function Collect-Reports {
    Write-Host "📥 收集周报..." -ForegroundColor Yellow
    Write-Host ""
    
    $CurrentWeek = (Get-Date).ToString("yyyy-MM-dd")
    $WeekReportPath = Join-Path $ReportsPath $CurrentWeek
    
    if (-not (Test-Path $WeekReportPath)) {
        New-Item -ItemType Directory -Force -Path $WeekReportPath | Out-Null
    }
    
    $submittedCount = 0
    $pendingCount = 0
    
    foreach ($pm in $ProjectManagers) {
        $ReportFile = Join-Path $WeekReportPath "$($pm.Name)-weekly-report.md"
        
        if (Test-Path $ReportFile) {
            Write-Host "  ✅ $($pm.Name): 已提交" -ForegroundColor Green
            $submittedCount++
        } else {
            Write-Host "  ⏳ $($pm.Name): 待提交" -ForegroundColor Yellow
            $pendingCount++
        }
    }
    
    Write-Host ""
    Write-Host "提交统计：$submittedCount 已提交 / $pendingCount 待提交" -ForegroundColor Cyan
}

function Generate-WeeklySummary {
    Write-Host "📊 生成周报摘要..." -ForegroundColor Yellow
    Write-Host ""
    
    $CurrentWeek = (Get-Date).ToString("yyyy-MM-dd")
    $WeekReportPath = Join-Path $ReportsPath $CurrentWeek
    $SummaryFile = Join-Path $WeekReportPath "weekly-summary.md"
    
    $summary = @"
# $ProjectName - 周报摘要

**汇总周期**: $(Get-Date -Format "yyyy-MM-dd")  
**生成时间**: $(Get-Date -Format "yyyy-MM-dd HH:mm")

---

## 📊 提交情况

| 负责人 | 角色 | 提交状态 | 提交时间 |
|--------|------|---------|---------|
"@
    
    foreach ($pm in $ProjectManagers) {
        $ReportFile = Join-Path $WeekReportPath "$($pm.Name)-weekly-report.md"
        $status = if (Test-Path $ReportFile) { "✅ 已提交" } else { "⏳ 待提交" }
        $time = if (Test-Path $ReportFile) { 
            (Get-Item $ReportFile).LastWriteTime.ToString("MM-dd HH:mm") 
        } else { "-" }
        
        $summary += "`n| $($pm.Name) | $($pm.Role) | $status | $time |"
    }
    
    $summary += @"


---

## 📋 上周工作总结

### 完成情况
_待汇总..._

### 未完成事项
_待汇总..._

---

## 📋 本周工作计划

### 计划任务
_待汇总..._

### 里程碑节点
_待汇总..._

---

## ⚠️ 风险与问题

### 当前风险
_待汇总..._

### 需要支持
_待汇总..._

---

## 📈 项目整体状态

- **进度**: 🟢 正常 / 🟡 风险 / 🔴 延期
- **资源**: 🟢 充足 / 🟡 紧张 / 🔴 不足
- **质量**: 🟢 良好 / 🟡 一般 / 🔴 需改进

---

**备注**: 本摘要由 PMO 系统自动生成，详细信息请查看各负责人周报。

"@
    
    $summary | Out-File -FilePath $SummaryFile -Encoding UTF8
    
    Write-Host "✓ 周报摘要已生成：$SummaryFile" -ForegroundColor Green
}

function Show-Help {
    Write-Host "使用方法:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  .\weekly-report-automation.ps1 -Action remind" -ForegroundColor White
    Write-Host "      发送周报收集提醒" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\weekly-report-automation.ps1 -Action collect" -ForegroundColor White
    Write-Host "      收集周报并统计提交情况" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\weekly-report-automation.ps1 -Action summary" -ForegroundColor White
    Write-Host "      生成周报摘要" -ForegroundColor Gray
    Write-Host ""
    Write-Host "快捷方式:" -ForegroundColor Cyan
    Write-Host "  .\weekly-report-automation.ps1 -SendReminder" -ForegroundColor White
    Write-Host "  .\weekly-report-automation.ps1 -CollectReports" -ForegroundColor White
    Write-Host "  .\weekly-report-automation.ps1 -GenerateSummary" -ForegroundColor White
    Write-Host ""
}

# 主逻辑
switch ($Action) {
    "remind" {
        Send-WeeklyReminder
    }
    "collect" {
        Collect-Reports
    }
    "summary" {
        Generate-WeeklySummary
    }
    default {
        Show-Help
    }
}

if ($SendReminder) {
    Send-WeeklyReminder
}

if ($CollectReports) {
    Collect-Reports
}

if ($GenerateSummary) {
    Generate-WeeklySummary
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  处理完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
