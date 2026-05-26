# IMAP Connection Test Script - Simplified
$imapHost = "outlook.office365.com"
$imapPort = 993
$email = "openclawPMO@outlook.com"
$password = "PMOopenclaw1."

Write-Host "Testing IMAP connection..." -ForegroundColor Cyan

try {
    $client = New-Object System.Net.Sockets.TcpClient($imapHost, $imapPort)
    Write-Host "TCP connected" -ForegroundColor Green
    
    $stream = $client.GetStream()
    $sslStream = New-Object System.Net.Security.SslStream($stream, $false, { $true })
    $sslStream.AuthenticateAsClient($imapHost)
    
    $writer = New-Object System.IO.StreamWriter($sslStream)
    $reader = New-Object System.IO.StreamReader($sslStream)
    $writer.AutoFlush = $true
    
    $greeting = $reader.ReadLine()
    Write-Host "Server: $greeting"
    
    $loginCmd = "A001 LOGIN " + $email + " " + $password
    $writer.WriteLine($loginCmd)
    Start-Sleep -Milliseconds 1000
    $response = $reader.ReadLine()
    Write-Host "Login Response: $response"
    
    if ($response -like "*OK*") {
        Write-Host "SUCCESS - IMAP authenticated!" -ForegroundColor Green
        
        $writer.WriteLine("A002 SELECT INBOX")
        Start-Sleep -Milliseconds 500
        $inboxResp = $reader.ReadLine()
        Write-Host "Inbox: $inboxResp"
        
        $writer.WriteLine("A003 LOGOUT")
        $reader.ReadLine() | Out-Null
    } else {
        Write-Host "FAILED - Check credentials" -ForegroundColor Red
    }
    
    $sslStream.Close()
    $client.Close()
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
