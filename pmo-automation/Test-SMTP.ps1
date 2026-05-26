# SMTP Test Script
# SMTP: smtp-mail.outlook.com:587 (STARTTLS)

$smtpServer = "smtp-mail.outlook.com"
$smtpPort = 587
$smtpUser = "openclawPMO@outlook.com"
$smtpPass = "PMOopenclaw1"
$recipient = $smtpUser

$subject = "SMTP Test - AI PMO System"
$body = "This is a test email from AI PMO System. If you receive this, SMTP is working."

Write-Host "SMTP Configuration:"
Write-Host "  Server: $smtpServer"
Write-Host "  Port: $smtpPort"
Write-Host "  User: $smtpUser"
Write-Host "  SSL: Yes"
Write-Host ""

try {
    $from = New-Object Net.Mail.MailAddress($smtpUser, "AI PMO System")
    $to = New-Object Net.Mail.MailAddress($recipient)
    $mail = New-Object Net.Mail.MailMessage($from, $to, $subject, $body)
    $mail.IsBodyHtml = $false

    $smtp = New-Object Net.Mail.SmtpClient($smtpServer, $smtpPort)
    $smtp.Credentials = New-Object Net.NetworkCredential($smtpUser, $smtpPass)
    $smtp.EnableSsl = $true

    Write-Host "Sending..."
    $smtp.Send($mail)
    Write-Host "SUCCESS: Email sent!" -ForegroundColor Green

    $mail.Dispose()
    $smtp.Dispose()
}
catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.InnerException) {
        Write-Host "Inner: $($_.Exception.InnerException.Message)" -ForegroundColor Red
    }
}
