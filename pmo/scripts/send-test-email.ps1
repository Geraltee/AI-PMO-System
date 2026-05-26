# Email Test using .NET SmtpClient
$email = "openclawPMO@outlook.com"
$appPassword = "vjpdxuqflwbiabcv"
$smtpHost = "smtp.office365.com"
$smtpPort = 587

Write-Host "=== Testing SMTP with .NET SmtpClient ===" -ForegroundColor Cyan

try {
    # Create SMTP client
    $smtp = New-Object System.Net.Mail.SmtpClient($smtpHost, $smtpPort)
    $smtp.EnableSsl = $true
    $smtp.UseDefaultCredentials = $false
    $smtp.Credentials = New-Object System.Net.NetworkCredential($email, $appPassword)
    $smtp.Timeout = 30000
    
    Write-Host "SMTP Client configured" -ForegroundColor Green
    
    # Create mail message
    $mail = New-Object System.Net.Mail.MailMessage
    $mail.From = New-Object System.Net.Mail.MailAddress($email, "AI PMO System")
    $mail.To.Add($email)
    $mail.Subject = "PMO Test - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $mail.Body = "Test email from AI PMO System.`r`nSent at: $(Get-Date)`r`n`r`nThis confirms email configuration is working."
    $mail.IsBodyHtml = $false
    
    Write-Host "Sending email..." -ForegroundColor Yellow
    
    $smtp.Send($mail)
    
    Write-Host "✅ EMAIL SENT SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "Check inbox at: $email"
    
    $mail.Dispose()
    $smtp.Dispose()
} catch {
    Write-Host "❌ SEND FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.InnerException) {
        Write-Host "Inner: $($_.Exception.InnerException.Message)" -ForegroundColor Red
    }
}
