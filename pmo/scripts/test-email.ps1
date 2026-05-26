# IMAP/SMTP Test with App Password
$imapHost = "outlook.office365.com"
$imapPort = 993
$smtpHost = "smtp.office365.com"
$smtpPort = 587
$email = "openclawPMO@outlook.com"
$appPassword = "vjpdxuqflwbiabcv"

Write-Host "=== IMAP Test ===" -ForegroundColor Cyan

try {
    $client = New-Object System.Net.Sockets.TcpClient($imapHost, $imapPort)
    Write-Host "TCP connected to IMAP" -ForegroundColor Green
    
    $stream = $client.GetStream()
    $sslStream = New-Object System.Net.Security.SslStream($stream, $false, { $true })
    $sslStream.AuthenticateAsClient($imapHost)
    
    $writer = New-Object System.IO.StreamWriter($sslStream)
    $reader = New-Object System.IO.StreamReader($sslStream)
    $writer.AutoFlush = $true
    
    $greeting = $reader.ReadLine()
    Write-Host "IMAP: $greeting"
    
    $loginCmd = "A001 LOGIN " + $email + " " + $appPassword
    $writer.WriteLine($loginCmd)
    Start-Sleep -Milliseconds 1000
    $response = $reader.ReadLine()
    Write-Host "IMAP Login: $response"
    
    if ($response -like "*OK*") {
        Write-Host "✅ IMAP SUCCESS" -ForegroundColor Green
        
        $writer.WriteLine("A002 SELECT INBOX")
        Start-Sleep -Milliseconds 500
        $inboxResp = $reader.ReadLine()
        Write-Host "Inbox: $inboxResp"
        
        $writer.WriteLine("A003 LOGOUT")
        $reader.ReadLine() | Out-Null
    } else {
        Write-Host "❌ IMAP FAILED" -ForegroundColor Red
    }
    
    $sslStream.Close()
    $client.Close()
} catch {
    Write-Host "IMAP Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== SMTP Test ===" -ForegroundColor Cyan

try {
    $smtpClient = New-Object System.Net.Sockets.TcpClient($smtpHost, $smtpPort)
    Write-Host "TCP connected to SMTP" -ForegroundColor Green
    
    $smtpStream = $smtpClient.GetStream()
    $smtpReader = New-Object System.IO.StreamReader($smtpStream)
    $smtpWriter = New-Object System.IO.StreamWriter($smtpStream)
    $smtpWriter.AutoFlush = $true
    
    $smtpGreeting = $smtpReader.ReadLine()
    Write-Host "SMTP: $smtpGreeting"
    
    $smtpWriter.WriteLine("EHLO PMO-System")
    Start-Sleep -Milliseconds 500
    do {
        $ehloResp = $smtpReader.ReadLine()
        Write-Host "EHLO: $ehloResp"
    } until ($ehloResp -like "*250 *")
    
    $smtpWriter.WriteLine("AUTH LOGIN")
    Start-Sleep -Milliseconds 500
    $authResp = $smtpReader.ReadLine()
    Write-Host "AUTH: $authResp"
    
    $encodedUser = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($email))
    $smtpWriter.WriteLine($encodedUser)
    Start-Sleep -Milliseconds 500
    $userResp = $smtpReader.ReadLine()
    Write-Host "User: $userResp"
    
    $encodedPass = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($appPassword))
    $smtpWriter.WriteLine($encodedPass)
    Start-Sleep -Milliseconds 1000
    $passResp = $smtpReader.ReadLine()
    Write-Host "Pass: $passResp"
    
    if ($passResp -like "*235*" -or $passResp -like "*OK*") {
        Write-Host "✅ SMTP AUTH SUCCESS" -ForegroundColor Green
        
        $smtpWriter.WriteLine("MAIL FROM:<$email>")
        Start-Sleep -Milliseconds 500
        $mailFromResp = $smtpReader.ReadLine()
        Write-Host "MAIL FROM: $mailFromResp"
        
        $smtpWriter.WriteLine("RCPT TO:<$email>")
        Start-Sleep -Milliseconds 500
        $rcptResp = $smtpReader.ReadLine()
        Write-Host "RCPT TO: $rcptResp"
        
        $smtpWriter.WriteLine("DATA")
        Start-Sleep -Milliseconds 500
        $dataResp = $smtpReader.ReadLine()
        Write-Host "DATA: $dataResp"
        
        $subject = "PMO Test Email - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        $body = "This is a test email from AI PMO System.`r`nSent at: $(Get-Date)"
        $message = "Subject: $subject`r`nFrom: AI PMO System <$email>`r`nTo: <$email>`r`n`r`n$body`r`n.`r`n"
        
        $smtpWriter.Write($message)
        Start-Sleep -Milliseconds 1000
        $sendResp = $smtpReader.ReadLine()
        Write-Host "SEND: $sendResp"
        
        if ($sendResp -like "*OK*" -or $sendResp -like "*250*") {
            Write-Host "✅ EMAIL SENT SUCCESSFULLY!" -ForegroundColor Green
        } else {
            Write-Host "❌ SEND FAILED: $sendResp" -ForegroundColor Red
        }
        
        $smtpWriter.WriteLine("QUIT")
        $smtpReader.ReadLine() | Out-Null
    } else {
        Write-Host "❌ SMTP AUTH FAILED: $passResp" -ForegroundColor Red
    }
    
    $smtpStream.Close()
    $smtpClient.Close()
} catch {
    Write-Host "SMTP Error: $($_.Exception.Message)" -ForegroundColor Red
}
