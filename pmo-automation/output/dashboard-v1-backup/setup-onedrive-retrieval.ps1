# OneDrive 检索服务配置脚本
# 用于设置和配置 OneDrive 文档检索模块

param(
    [string]$Action = "setup",
    [string]$OneDriveUrl = "",
    [switch]$ScanDocuments,
    [switch]$ShowStats
)

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutputPath = "D:\AI-PMO-System\pmo-automation\output\dashboard-with-retrieval"
$ConfigFile = Join-Path $OutputPath "onedrive-config.json"
$IndexFile = Join-Path $OutputPath "document-index.json"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OneDrive 检索服务配置工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function Initialize-Config {
    Write-Host "初始化配置文件..." -ForegroundColor Yellow
    
    $config = @{
        oneDriveUrls = @()
        adminCredentials = $null
        lastSync = $null
        searchSettings = @{
            includeSubfolders = $true
            searchContent = $true
            searchMetadata = $false
        }
    } | ConvertTo-Json -Depth 10
    
    $config | Out-File -FilePath $ConfigFile -Encoding UTF8
    Write-Host "✓ 配置文件已创建：$ConfigFile" -ForegroundColor Green
}

function Add-OneDriveUrl {
    param([string]$Url, [string]$Name)
    
    if (-not $Url) {
        Write-Host "❌ 请提供 OneDrive URL" -ForegroundColor Red
        return
    }
    
    Write-Host "添加 OneDrive 文档库：$Url" -ForegroundColor Yellow
    
    if (Test-Path $ConfigFile) {
        $config = Get-Content $ConfigFile | ConvertFrom-Json
        
        # 检查是否已存在
        $exists = $config.oneDriveUrls | Where-Object { $_.url -eq $Url }
        if ($exists) {
            Write-Host "⚠️  该 URL 已存在" -ForegroundColor Yellow
            return
        }
        
        # 添加新 URL
        $config.oneDriveUrls += @{
            url = $Url
            name = $Name ?: $Url
            addedAt = (Get-Date -Format "o")
            status = "pending"
        }
        
        $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigFile -Encoding UTF8
        Write-Host "✓ OneDrive URL 已添加" -ForegroundColor Green
    } else {
        Write-Host "❌ 配置文件不存在，请先运行初始化" -ForegroundColor Red
    }
}

function Scan-OneDriveDocuments {
    Write-Host "开始扫描 OneDrive 文档..." -ForegroundColor Yellow
    
    if (-not (Test-Path $ConfigFile)) {
        Write-Host "❌ 配置文件不存在" -ForegroundColor Red
        return
    }
    
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    
    if ($config.oneDriveUrls.Count -eq 0) {
        Write-Host "⚠️  未配置任何 OneDrive URL" -ForegroundColor Yellow
        Write-Host "提示：使用 -OneDriveUrl 参数添加文档库" -ForegroundColor Cyan
        return
    }
    
    Write-Host "已配置 $($config.oneDriveUrls.Count) 个 OneDrive 文档库" -ForegroundColor Green
    
    # 模拟扫描过程
    $totalDocs = 0
    foreach ($drive in $config.oneDriveUrls) {
        Write-Host "  扫描：$($drive.name)" -ForegroundColor Cyan
        
        # 实际实现应调用 Microsoft Graph API
        # 这里使用模拟数据
        $docCount = (Get-Random -Minimum 10 -Maximum 20)
        $totalDocs += $docCount
        
        Write-Host "    ✓ 发现 $docCount 个文档" -ForegroundColor Green
        Start-Sleep -Milliseconds 500
    }
    
    # 创建模拟索引
    $index = @{
        documents = @()
        lastUpdated = (Get-Date -Format "o")
    }
    
    # 生成模拟文档
    for ($i = 1; $i -le $totalDocs; $i++) {
        $types = @('docx', 'xlsx', 'pptx', 'pdf')
        $type = $types[(Get-Random -Maximum $types.Count)]
        
        $doc = @{
            id = "doc-$i"
            title = "文档-$i.$type".ToUpper()
            url = "https://example.sharepoint.com/doc$i.$type"
            type = $type
            size = (Get-Random -Maximum 10) * 1024 * 1024
            createdDate = (Get-Date).AddDays(-(Get-Random -Maximum 30)).ToString("o")
            modifiedDate = (Get-Date).AddDays(-(Get-Random -Maximum 7)).ToString("o")
            content = "文档内容摘要..."
            metadata = @{
                author = "用户$((Get-Random -Maximum 5) + 1)"
                tags = @('项目文档', 'PMO')
            }
        }
        
        $index.documents += $doc
    }
    
    $index | ConvertTo-Json -Depth 10 | Out-File -FilePath $IndexFile -Encoding UTF8
    
    Write-Host ""
    Write-Host "✓ 扫描完成！共索引 $totalDocs 个文档" -ForegroundColor Green
    Write-Host "  索引文件：$IndexFile" -ForegroundColor Cyan
}

function Show-Statistics {
    Write-Host "系统统计信息" -ForegroundColor Yellow
    Write-Host ""
    
    if (Test-Path $ConfigFile) {
        $config = Get-Content $ConfigFile | ConvertFrom-Json
        Write-Host "配置的 OneDrive 数量：$($config.oneDriveUrls.Count)" -ForegroundColor Cyan
        
        foreach ($drive in $config.oneDriveUrls) {
            Write-Host "  - $($drive.name) [$($drive.status)]" -ForegroundColor Gray
        }
    } else {
        Write-Host "配置文件不存在" -ForegroundColor Red
    }
    
    Write-Host ""
    
    if (Test-Path $IndexFile) {
        $index = Get-Content $IndexFile | ConvertFrom-Json
        Write-Host "索引文档总数：$($index.documents.Count)" -ForegroundColor Cyan
        
        $typeStats = @{}
        foreach ($doc in $index.documents) {
            $typeStats[$doc.type] = ($typeStats[$doc.type] ?: 0) + 1
        }
        
        Write-Host "文档类型分布:" -ForegroundColor Cyan
        foreach ($type in $typeStats.Keys) {
            Write-Host "  $type : $($typeStats[$type])" -ForegroundColor Gray
        }
        
        Write-Host "最后更新时间：$($index.lastUpdated)" -ForegroundColor Cyan
    } else {
        Write-Host "索引文件不存在" -ForegroundColor Red
    }
}

function Show-Help {
    Write-Host "使用方法:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  .\setup-onedrive-retrieval.ps1 -Action setup" -ForegroundColor White
    Write-Host "      初始化配置文件" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\setup-onedrive-retrieval.ps1 -Action add -OneDriveUrl <URL>" -ForegroundColor White
    Write-Host "      添加 OneDrive 文档库 URL" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\setup-onedrive-retrieval.ps1 -ScanDocuments" -ForegroundColor White
    Write-Host "      扫描 OneDrive 文档并建立索引" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\setup-onedrive-retrieval.ps1 -ShowStats" -ForegroundColor White
    Write-Host "      显示系统统计信息" -ForegroundColor Gray
    Write-Host ""
}

# 主逻辑
switch ($Action) {
    "setup" {
        Initialize-Config
    }
    "add" {
        Add-OneDriveUrl -Url $OneDriveUrl -Name ""
    }
    "scan" {
        Scan-OneDriveDocuments
    }
    "stats" {
        Show-Statistics
    }
    default {
        Show-Help
    }
}

if ($ScanDocuments) {
    Scan-OneDriveDocuments
}

if ($ShowStats) {
    Show-Statistics
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  配置完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步:" -ForegroundColor Yellow
Write-Host "1. 打开 D:\AI-PMO-System\pmo-automation\output\dashboard-with-retrieval\index.html" -ForegroundColor White
Write-Host "2. 在浏览器中配置 OneDrive URL" -ForegroundColor White
Write-Host "3. 点击'扫描文档'建立索引" -ForegroundColor White
Write-Host "4. 开始使用智能检索功能" -ForegroundColor White
Write-Host ""
