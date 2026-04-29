$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$scriptPath = Join-Path $projectRoot "tools\export_excel_to_json.py"

if (-not (Test-Path $scriptPath)) {
    Write-Host "[ERROR] Missing script: $scriptPath" -ForegroundColor Red
    exit 1
}

$pythonExe = $null
if (Get-Command py -ErrorAction SilentlyContinue) {
    $pythonExe = "py"
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonExe = "python"
}

if (-not $pythonExe) {
    Write-Host "[ERROR] Python launcher not found. Install Python 3 first." -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Project : $projectRoot"
Write-Host "[INFO] Python  : $pythonExe"
Write-Host "[INFO] Running export..."

if ($pythonExe -eq "py") {
    & py $scriptPath
} else {
    & python $scriptPath
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Export failed with code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "[DONE] Excel -> JSON export completed."
exit 0
