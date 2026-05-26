# PMO 项目导出为 Excel/CSV - 用于 Smartsheet 导入
# 用法：.\export-to-smartsheet.ps1 [项目 ID]

param(
    [string]$ProjectId = "ALL"
)

$PMO_PROJECTS = "D:\AI-PMO-System\pmo\projects"
$EXPORT_DIR = "D:\AI-PMO-System\pmo\exports"
$DATE = Get-Date -Format "yyyyMMdd-HHmmss"

# 确保导出目录存在
if (-not (Test-Path $EXPORT_DIR)) {
    New-Item -ItemType Directory -Path $EXPORT_DIR -Force | Out-Null
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   PMO 项目导出工具 - Smartsheet/Excel" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 获取项目文件
if ($ProjectId -eq "ALL") {
    $projectFiles = Get-ChildItem $PMO_PROJECTS -Filter "*.md"
} else {
    $projectFiles = Get-ChildItem $PMO_PROJECTS -Filter "$ProjectId.md"
}

if ($projectFiles.Count -eq 0) {
    Write-Host "未找到项目文件" -ForegroundColor Red
    exit 1
}

# 创建 CSV 内容
$csvContent = "项目 ID，项目名称，状态，优先级，负责人，创建日期，最后更新，风险数量`n"

foreach ($file in $projectFiles) {
    $content = Get-Content $file.FullName -Encoding UTF8 -Raw
    
    # 提取项目信息
    $projectId = if ($content -match '项目 ID \| ([\w-]+)') { $matches[1] } else { "未知" }
    $projectName = if ($content -match '# 项目档案：(.+)') { $matches[1].Trim() } else { "未知" }
    $status = if ($content -match '(🟢|🟡|🔴)') { $matches[1] } else { "⚪" }
    $priority = if ($content -match '优先级 \| (P[0-3])') { $matches[1] } else { "P2" }
    $owner = if ($content -match '项目负责人 \| (.+)') { $matches[1].Trim() } else { "待填写" }
    $created = if ($content -match '创建日期 \| (.+)') { $matches[1].Trim() } else { "未知" }
    $updated = if ($content -match '\*最后更新：(.+)\*') { $matches[1].Trim() } else { "未知" }
    
    # 计算风险数量
    $riskCount = ([regex]::Matches($content, '\| .+ \| .+ \| .+ \| .+ \| .+ \|')).Count
    
    $csvContent += "$projectId,$projectName,$status,$priority,$owner,$created,$updated,$riskCount`n"
}

# 保存 CSV
$exportFile = "$EXPORT_DIR\pmo-projects-$DATE.csv"
$csvContent | Out-File -FilePath $exportFile -Encoding UTF8

Write-Host "✅ 导出完成！" -ForegroundColor Green
Write-Host ""
Write-Host "文件位置：$exportFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 导入 Smartsheet 步骤:" -ForegroundColor Yellow
Write-Host "  1. 打开 Smartsheet"
Write-Host "  2. 文件 → 导入 → 上传 CSV"
Write-Host "  3. 选择导出的文件"
Write-Host "  4. 映射列并完成导入"
Write-Host ""
Write-Host "📋 导入 Excel 步骤:" -ForegroundColor Yellow
Write-Host "  1. 打开 Excel"
Write-Host "  2. 数据 → 从文本/CSV"
Write-Host "  3. 选择导出的文件"
Write-Host "  4. 设置分隔符为逗号"
Write-Host ""

# 自动打开文件
Write-Host "正在打开文件..." -ForegroundColor Gray
Invoke-Item $exportFile
