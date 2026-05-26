# AI PMO Web Server - PowerShell Version
$port = 5000
$root = "D:\AI-PMO-System\pmo-automation\output\dashboard-with-retrieval"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AI PMO Web Server" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Root: $root" -ForegroundColor Yellow
Write-Host "  Port: $port" -ForegroundColor Yellow
Write-Host ""
Write-Host "  URL: http://localhost:$port/dashboard.html" -ForegroundColor Green
Write-Host ""
Write-Host "  Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Server started" -ForegroundColor Green

$mimeTypeMap = @{
    ".html" = "text/html"
    ".css" = "text/css"
    ".js" = "application/javascript"
    ".json" = "application/json"
    ".png" = "image/png"
    ".jpg" = "image/jpeg"
    ".gif" = "image/gif"
    ".svg" = "image/svg+xml"
    ".ico" = "image/x-icon"
}

try {
    while ($true) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $path = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrEmpty($path)) {
            $path = "dashboard.html"
        }
        
        $filePath = Join-Path $root $path
        
        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $mimeType = if ($mimeTypeMap[$ext]) { $mimeTypeMap[$ext] } else { "application/octet-stream" }
            
            $content = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType = $mimeType
            $response.ContentLength64 = $content.Length
            $response.OutputStream.Write($content, 0, $content.Length)
            
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 200 - $path" -ForegroundColor Gray
        } else {
            $errorMsg = "404 - File Not Found: $path"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($errorMsg)
            $response.StatusCode = 404
            $response.ContentType = "text/plain"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 404 - $path" -ForegroundColor Red
        }
        
        $response.OutputStream.Close()
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "Server stopped" -ForegroundColor Yellow
}
