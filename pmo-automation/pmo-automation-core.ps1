# PMO Automation Core Script
# AI 项目自动化管理系统核心脚本
# Version: 1.0.0

param(
    [string]$Action = "status",
    [string]$ProjectDataPath = "C:\Users\Administrator\.openclaw\workspace\pmo-automation\project-data.json"
)

$ErrorActionPreference = "Stop"
$OutputPath = "C:\Users\Administrator\.openclaw\workspace\pmo-automation\output"
if (!(Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath | Out-Null }

function Get-ProjectData {
    param([string]$Path = $ProjectDataPath)
    return Get-Content $Path -Raw | ConvertFrom-Json
}

function New-ProjectDashboard {
    param($ProjectData)
    
    $html = @"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>项目 Dashboard - $($ProjectData.projectInfo.name)</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Microsoft YaHei', Arial, sans-serif; background: #f5f7fa; padding: 20px; }
        .container { max-width: 1400px; margin: 0 auto; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 20px; }
        .header h1 { font-size: 28px; margin-bottom: 10px; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 20px; }
        .stat-card { background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .stat-card h3 { color: #667eea; font-size: 14px; margin-bottom: 10px; }
        .stat-card .value { font-size: 32px; font-weight: bold; color: #333; }
        .section { background: white; border-radius: 10px; padding: 25px; margin-bottom: 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .section h2 { color: #333; margin-bottom: 20px; padding-bottom: 10px; border-bottom: 2px solid #667eea; }
        .team-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 15px; }
        .team-member { background: #f8f9fa; padding: 15px; border-radius: 8px; border-left: 4px solid #667eea; }
        .team-member h4 { color: #333; margin-bottom: 5px; }
        .team-member .role { color: #667eea; font-size: 13px; margin-bottom: 8px; }
        .team-member .email { color: #666; font-size: 12px; }
        .timeline { position: relative; padding-left: 30px; }
        .timeline-item { position: relative; padding-bottom: 30px; border-left: 2px solid #667eea; padding-left: 20px; }
        .timeline-item::before { content: ''; position: absolute; left: -6px; top: 0; width: 10px; height: 10px; background: #667eea; border-radius: 50%; }
        .timeline-item h4 { color: #333; margin-bottom: 5px; }
        .timeline-item .dates { color: #666; font-size: 13px; margin-bottom: 8px; }
        .timeline-item .owner { background: #667eea; color: white; padding: 2px 8px; border-radius: 3px; font-size: 12px; }
        .milestone-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; }
        .milestone { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 15px; border-radius: 8px; text-align: center; }
        .milestone .date { font-size: 20px; font-weight: bold; margin-bottom: 5px; }
        .generated-time { text-align: center; color: #999; font-size: 12px; margin-top: 30px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Project: $($ProjectData.projectInfo.name)</h1>
            <p>Version: $($ProjectData.projectInfo.version) | Status: $($ProjectData.projectInfo.status)</p>
        </div>
        <div class="stats-grid">
            <div class="stat-card"><h3>Team Members</h3><div class="value">$($ProjectData.teamMembers.Count)</div></div>
            <div class="stat-card"><h3>Project Phases</h3><div class="value">$($ProjectData.projectPhases.Count)</div></div>
            <div class="stat-card"><h3>Milestones</h3><div class="value">$($ProjectData.milestones.Count)</div></div>
        </div>
        <div class="section">
            <h2>Team Members</h2>
            <div class="team-grid">
"@
    foreach ($member in $ProjectData.teamMembers) {
        $html += "<div class='team-member'><h4>$($member.name)</h4><div class='role'>$($member.role)</div><div class='email'>$($member.email)</div></div>"
    }
    $html += "</div></div>"
    $html += "<div class='section'><h2>Project Timeline</h2><div class='timeline'>"
    foreach ($phase in $ProjectData.projectPhases) {
        $html += "<div class='timeline-item'><h4>$($phase.phase)</h4><div class='dates'>$($phase.startDate) - $($phase.endDate)</div><span class='owner'>Owner: $($phase.owner)</span></div>"
    }
    $html += "</div></div>"
    $html += "<div class='section'><h2>Milestones</h2><div class='milestone-grid'>"
    foreach ($ms in $ProjectData.milestones) {
        $html += "<div class='milestone'><div class='date'>$($ms.date)</div><div class='name'>$($ms.name)</div></div>"
    }
    $html += "</div></div>"
    $html += "<div class='generated-time'>Generated: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))</div>"
    $html += "</div></body></html>"
    
    $dashboardPath = Join-Path $OutputPath "project-dashboard.html"
    $html | Out-File -FilePath $dashboardPath -Encoding UTF8
    Write-Host "Dashboard generated: $dashboardPath"
    return $dashboardPath
}

function New-ProjectSOP {
    param($ProjectData)
    $sop = "# Project SOP - $($ProjectData.projectInfo.name)`n`n"
    $sop += "Version: $($ProjectData.projectInfo.version)`n"
    $sop += "Generated: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))`n`n"
    $sop += "## Team Members`n`n"
    foreach ($member in $ProjectData.teamMembers) {
        $sop += "### $($member.name) - $($member.role)`n"
        $sop += "- Email: $($member.email)`n"
        $sop += "- Responsibilities: $($member.responsibilities -join ', ')`n`n"
    }
    $sop += "## Project Phases`n`n"
    foreach ($phase in $ProjectData.projectPhases) {
        $sop += "### $($phase.phase)`n"
        $sop += "- Period: $($phase.startDate) to $($phase.endDate)`n"
        $sop += "- Owner: $($phase.owner)`n"
        $sop += "- Deliverables: $($phase.deliverables -join ', ')`n`n"
    }
    $sopPath = Join-Path $OutputPath "project-SOP.md"
    $sop | Out-File -FilePath $sopPath -Encoding UTF8
    Write-Host "SOP generated: $sopPath"
    return $sopPath
}

function Send-ProjectKickoffEmail {
    param($ProjectData)
    $email = "Subject: Project Kickoff - $($ProjectData.projectInfo.name)`n`n"
    $email += "Dear Team,`n`n"
    $email += "Project '$($ProjectData.projectInfo.name)' is now starting!`n`n"
    $email += "Project Info:`n"
    $email += "- Version: $($ProjectData.projectInfo.version)`n"
    $email += "- Period: $($ProjectData.projectInfo.startDate) to $($ProjectData.projectInfo.endDate)`n`n"
    $email += "Team Members:`n"
    foreach ($member in $ProjectData.teamMembers) {
        $email += "- $($member.name) ($($member.role)): $($member.email)`n"
    }
    $email += "`nPlease check the attached Dashboard and SOP for details.`n`n"
    $email += "Best regards,`nAI PMO System"
    
    $emailPath = Join-Path $OutputPath "kickoff-email.txt"
    $email | Out-File -FilePath $emailPath -Encoding UTF8
    Write-Host "Kickoff email draft generated: $emailPath"
    return $emailPath
}

# Main execution
$projectData = Get-ProjectData

switch ($Action) {
    "dashboard" { New-ProjectDashboard -ProjectData $projectData }
    "sop" { New-ProjectSOP -ProjectData $projectData }
    "email" { Send-ProjectKickoffEmail -ProjectData $projectData }
    "all" {
        New-ProjectDashboard -ProjectData $projectData
        New-ProjectSOP -ProjectData $projectData
        Send-ProjectKickoffEmail -ProjectData $projectData
    }
    default {
        Write-Host "PMO Automation System v1.0"
        Write-Host "Project: $($projectData.projectInfo.name)"
        Write-Host "Status: $($projectData.projectInfo.status)"
        Write-Host "Team: $($projectData.teamMembers.Count) members"
        Write-Host "Phases: $($projectData.projectPhases.Count)"
        Write-Host "`nUsage: .\pmo-automation-core.ps1 -Action [dashboard|sop|email|all]"
    }
}
