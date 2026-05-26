<#
.SYNOPSIS
    SOP 生成器模块
.DESCRIPTION
    生成标准操作流程 (SOP) 文档
#>

# SOP 模板库
$SOPTemplates = @{
    'ProjectKickoff' = @{
        Title = '项目启动流程'
        Version = '1.0'
        Sections = @(
            @{ Name = '目的'; Content = '规范项目启动流程，确保项目顺利开始' }
            @{ Name = '适用范围'; Content = '所有新立项项目' }
            @{ Name = '职责'; Content = '项目经理负责执行，部门经理负责审批' }
            @{ Name = '流程步骤'; Content = @"
1. 项目立项申请
   - 填写项目立项表
   - 明确项目目标和范围
   - 预估资源和时间

2. 立项审批
   - 部门经理审核
   - 管理层审批
   - 分配项目编号

3. 团队组建
   - 确定项目经理
   - 招募项目成员
   - 明确角色职责

4. 启动会议
   - 召开项目启动会
   - 介绍项目背景
   - 确认工作计划

5. 文档归档
   - 整理项目文档
   - 建立项目档案
   - 设置访问权限
"@ }
            @{ Name = '相关文档'; Content = '项目立项表、项目章程、WBS 分解表' }
        )
    }
    'ChangeManagement' = @{
        Title = '变更管理流程'
        Version = '1.0'
        Sections = @(
            @{ Name = '目的'; Content = '规范项目变更管理，控制变更风险' }
            @{ Name = '适用范围'; Content = '项目执行过程中的所有变更' }
            @{ Name = '职责'; Content = '项目经理负责评估，变更控制委员会负责审批' }
            @{ Name = '流程步骤'; Content = @"
1. 变更申请
   - 填写变更申请单
   - 说明变更原因
   - 评估变更影响

2. 变更评估
   - 技术可行性评估
   - 成本影响评估
   - 时间影响评估

3. 变更审批
   - 变更控制委员会审议
   - 批准/拒绝/搁置
   - 记录审批意见

4. 变更实施
   - 更新项目计划
   - 执行变更内容
   - 验证变更结果

5. 变更关闭
   - 确认变更完成
   - 更新相关文档
   - 归档变更记录
"@ }
            @{ Name = '相关文档'; Content = '变更申请单、变更日志、影响分析报告' }
        )
    }
    'QualityControl' = @{
        Title = '质量控制流程'
        Version = '1.0'
        Sections = @(
            @{ Name = '目的'; Content = '确保项目交付物符合质量要求' }
            @{ Name = '适用范围'; Content = '项目所有交付物' }
            @{ Name = '职责'; Content = '质量经理负责监督，项目成员负责执行' }
            @{ Name = '流程步骤'; Content = @"
1. 质量标准制定
   - 确定质量指标
   - 制定验收标准
   - 建立检查清单

2. 过程检查
   - 定期质量审查
   - 过程审计
   - 问题记录

3. 交付物评审
   - 内部评审
   - 客户评审
   - 整改完善

4. 质量报告
   - 编制质量报告
   - 分析质量趋势
   - 提出改进建议

5. 持续改进
   - 总结经验教训
   - 优化流程
   - 更新标准
"@ }
            @{ Name = '相关文档'; Content = '质量计划、检查清单、质量报告' }
        )
    }
    'RiskManagement' = @{
        Title = '风险管理流程'
        Version = '1.0'
        Sections = @(
            @{ Name = '目的'; Content = '识别、评估和应对项目风险' }
            @{ Name = '适用范围'; Content = '项目全生命周期' }
            @{ Name = '职责'; Content = '项目经理负责统筹，团队成员参与' }
            @{ Name = '流程步骤'; Content = @"
1. 风险识别
   - 头脑风暴
   - 专家访谈
   - 历史数据分析

2. 风险评估
   - 评估发生概率
   - 评估影响程度
   - 确定风险等级

3. 风险应对规划
   - 制定应对策略
   - 分配应对责任
   - 准备应急计划

4. 风险监控
   - 定期风险审查
   - 跟踪风险状态
   - 识别新风险

5. 风险应对执行
   - 执行应对措施
   - 更新风险登记册
   - 记录应对结果
"@ }
            @{ Name = '相关文档'; Content = '风险登记册、风险评估表、应对计划' }
        )
    }
}

function Generate-SOPs {
    param(
        [string]$ProjectId = 'all',
        [array]$SOPTypes = @('ProjectKickoff', 'ChangeManagement', 'QualityControl', 'RiskManagement')
    )
    
    Write-Host "[SOP] 开始生成 SOP 文档..." -ForegroundColor Cyan
    
    $outputPath = Join-Path $ScriptDir '..\output\sops'
    if (-not (Test-Path $outputPath)) {
        New-Item -ItemType Directory -Force -Path $outputPath | Out-Null
    }
    
    $generatedSOPs = @()
    
    foreach ($sopType in $SOPTypes) {
        $template = $SOPTemplates[$sopType]
        if (-not $template) {
            Write-Host "  [WARN] 未知 SOP 类型：$sopType" -ForegroundColor Yellow
            continue
        }
        
        Write-Host "`n  生成：$($template.Title)" -ForegroundColor Yellow
        
        $sopContent = Generate-SOPContent -Template $template -ProjectId $ProjectId
        $fileName = "$sopType-SOP-$(Get-Date -Format 'yyyyMMdd').md"
        $filePath = Join-Path $outputPath $fileName
        
        $sopContent | Out-File $filePath -Encoding UTF8
        $generatedSOPs += $filePath
        
        Write-Host "    [OK] 已保存：$fileName" -ForegroundColor Green
    }
    
    # 生成 HTML 版本
    Generate-SOPHTML -SOPs $generatedSOPs -OutputPath $outputPath
    
    Write-Host "`n[OK] SOP 生成完成，共 $($generatedSOPs.Count) 个文档" -ForegroundColor Green
    
    return $generatedSOPs
}

function Generate-SOPContent {
    param(
        [object]$Template,
        [string]$ProjectId
    )
    
    $content = @"
# $($Template.Title)

**版本号:** $($Template.Version)  
**生成日期:** $(Get-Date -Format 'yyyy-MM-dd')  
**项目 ID:** $(if ($ProjectId -eq 'all') { '通用' } else { $ProjectId })

---

"@
    
    foreach ($section in $Template.Sections) {
        $content += @"
## $($section.Name)

$($section.Content)

"@
    }
    
    $content += @"
---

*本文档由 PMO 自动化管理系统生成*
*最后更新：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
"@
    
    return $content
}

function Generate-SOPHTML {
    param(
        [array]$SOPs,
        [string]$OutputPath
    )
    
    $html = @"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SOP 文档库</title>
    <style>
        body { 
            font-family: 'Segoe UI', 'Microsoft YaHei', sans-serif; 
            max-width: 900px; 
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
            text-align: center;
        }
        .header h1 { margin: 0; }
        .header p { opacity: 0.9; margin-top: 10px; }
        
        .sop-list {
            background: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .sop-item {
            padding: 20px;
            border-bottom: 1px solid #eee;
            transition: background 0.2s;
        }
        .sop-item:hover {
            background: #f8f9fa;
        }
        .sop-item:last-child {
            border-bottom: none;
        }
        .sop-item h3 {
            color: #667eea;
            margin: 0 0 10px 0;
        }
        .sop-item p {
            color: #666;
            margin: 5px 0;
        }
        .sop-item a {
            display: inline-block;
            margin-top: 10px;
            padding: 8px 16px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 5px;
        }
        .sop-item a:hover {
            background: #5a6fd6;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>📋 SOP 标准操作流程文档库</h1>
        <p>生成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    
    <div class="sop-list">
"@
    
    foreach ($sopPath in $SOPs) {
        $fileName = Split-Path $sopPath -Leaf
        $sopName = $fileName -replace '-\d{8}\.md$', ''
        
        $html += @"
        <div class="sop-item">
            <h3>$sopName</h3>
            <p>文件：$fileName</p>
            <p>生成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm')</p>
            <a href="$fileName" target="_blank">查看文档</a>
        </div>
"@
    }
    
    $html += @"
    </div>
</body>
</html>
"@
    
    $htmlPath = Join-Path $OutputPath 'sop-index.html'
    $html | Out-File $htmlPath -Encoding UTF8
    Write-Host "  [OK] SOP 索引已生成：sop-index.html" -ForegroundColor Green
}

function Get-SOPTemplate {
    param([string]$Type)
    return $SOPTemplates[$Type]
}

function Add-CustomSOP {
    param(
        [string]$Type,
        [string]$Title,
        [array]$Sections
    )
    
    $SOPTemplates[$Type] = @{
        Title = $Title
        Version = '1.0'
        Sections = $Sections
    }
    
    Write-Host "[SOP] 已添加自定义 SOP 模板：$Title" -ForegroundColor Green
}
