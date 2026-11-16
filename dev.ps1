# Auto-cleanup orphaned processes on port 8181/8080 before starting
$conns = Get-NetTCPConnection -LocalPort 8181, 8080 -ErrorAction SilentlyContinue
if ($conns) {
    $procIds = $conns | Select-Object -ExpandProperty OwningProcess -Unique
    foreach ($p in $procIds) {
        if ($p -gt 0) {
            Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
        }
    }
    Start-Sleep -Milliseconds 600
}

Write-Host "Starting Dart Frog development server..." -ForegroundColor Cyan
dart_frog dev @args
