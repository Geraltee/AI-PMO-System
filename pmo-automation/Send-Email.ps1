# 项目启动邮件发送脚本
# SMTP: smtp-mail.outlook.com:587 (STARTTLS)
# 发件人：openclawPMO@outlook.com

$smtpServer = "smtp-mail.outlook.com"
$smtpPort = 587
$smtpUser = "openclawPMO@outlook.com"
$smtpPass = "PMOopenclaw1"

# 收件人列表
$recipients = @(
    "zhangsan@company.com",
    "lisi@company.com",
    "wangwu@company.com",
    "zhaoliu@company.com",
    "chenqi@company.com",
    "liuba@company.com",
    "zhoujiu@company.com",
    "wushi@company.com",
    "zhengshiyi@company.com",
    "qianshier@company.com",
    "duyu5@lenovo.com",
    "zhuran1@lenovo.com"
)

# 邮件内容
$subject = "[项目启动] AI Smart Customer Service Upgrade - 请各位成员查收"
$body = @"
<html>
<body>
<h2>各位项目组成员，大家好！</h2>

<p>很高兴宣布，<strong>AI Smart Customer Service Upgrade</strong> 项目正式启动！</p>

<h3>项目基本信息</h3>
<ul>
    <li><strong>项目名称</strong>: AI Smart Customer Service Upgrade</li>
    <li><strong>项目版本</strong>: V1.0</li>
    <li><strong>项目周期</strong>: 2026-04-04 至 2026-07-04</li>
    <li><strong>项目状态</strong>: Starting</li>
</ul>

<h3>团队成员及角色</h3>
<ul>
    <li><strong>Zhang San</strong> (Project Manager): zhangsan@company.com</li>
    <li><strong>Li Si</strong> (Tech Lead): lisi@company.com</li>
    <li><strong>Wang Wu</strong> (Backend Developer): wangwu@company.com</li>
    <li><strong>Zhao Liu</strong> (Frontend Developer): zhaoliu@company.com</li>
    <li><strong>Chen Qi</strong> (UI/UX Designer): chenqi@company.com</li>
    <li><strong>Liu Ba</strong> (Test Engineer): liuba@company.com</li>
    <li><strong>Zhou Jiu</strong> (DevOps Engineer): zhoujiu@company.com</li>
    <li><strong>Wu Shi</strong> (Product Specialist): wushi@company.com</li>
    <li><strong>Zheng Shi Yi</strong> (Data Analyst): zhengshiyi@company.com</li>
    <li><strong>Qian Shi Er</strong> (Security Engineer): qianshier@company.com</li>
    <li><strong>Olivia</strong> (Business Representative): duyu5@lenovo.com</li>
    <li><strong>Lisa</strong> (Business Representative): zhuran1@lenovo.com</li>
</ul>

<h3>项目阶段安排</h3>
<ol>
    <li><strong>Requirement Analysis</strong> (04-04 ~ 04-18) - 负责人：Wu Shi</li>
    <li><strong>System Design</strong> (04-19 ~ 05-03) - 负责人：Li Si</li>
    <li><strong>UI/UX Design</strong> (04-19 ~ 05-10) - 负责人：Chen Qi</li>
    <li><strong>Development</strong> (05-04 ~ 06-14) - 负责人：Wang Wu</li>
    <li><strong>Testing</strong> (06-15 ~ 06-28) - 负责人：Liu Ba</li>
    <li><strong>Deployment</strong> (06-29 ~ 07-04) - 负责人：Zhou Jiu</li>
</ol>

<h3>关键里程碑</h3>
<ul>
    <li>2026-04-04: Project Kickoff</li>
    <li>2026-04-18: Requirement Review Complete</li>
    <li>2026-05-03: Design Review Complete</li>
    <li>2026-06-14: Development Complete</li>
    <li>2026-06-28: Testing Complete</li>
    <li>2026-07-04: Go Live</li>
</ul>

<h3>下一步行动</h3>
<ol>
    <li><strong>项目启动会</strong>: 将于近期召开，具体时间另行通知</li>
    <li><strong>需求分析阶段</strong>: 立即开始，请相关成员做好准备</li>
    <li><strong>文档查阅</strong>: Dashboard 和 SOP 文档将另行发送</li>
</ol>

<p>如有任何问题，请随时与项目经理联系。</p>

<p>祝项目顺利！</p>

<hr>
<p style="color: #666; font-size: 12px;">此邮件由 AI PMO 自动化系统生成<br>
发送时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
</body>
</html>
"@

# 创建邮件
$mail = New-Object Net.Mail.MailMessage
$mail.From = $smtpUser
$mail.FromDisplayName = "AI PMO System"

# 添加所有收件人
foreach ($recipient in $recipients) {
    $mail.To.Add($recipient)
}

$mail.Subject = $subject
$mail.Body = $body
$mail.IsBodyHtml = $true

# 创建 SMTP 客户端
$smtp = New-Object Net.Mail.SmtpClient($smtpServer, $smtpPort)
$smtp.Credentials = New-Object Net.NetworkCredential($smtpUser, $smtpPass)
$smtp.EnableSsl = $true

try {
    Write-Host "正在发送邮件到 $($recipients.Count) 个收件人..."
    $smtp.Send($mail)
    Write-Host "邮件发送成功！"
    Write-Host "收件人列表:"
    foreach ($r in $recipients) {
        Write-Host "  - $r"
    }
} catch {
    Write-Host "邮件发送失败：$($_.Exception.Message)"
    Write-Host "内部错误：$($_.Exception.InnerException.Message)"
} finally {
    $mail.Dispose()
    $smtp.Dispose()
}
