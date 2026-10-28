param(
    [string]$Server = "(localdb)\MSSQLLocalDB",
    [string]$ScriptPath = "$PSScriptRoot\init_db.sql"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ScriptPath)) {
    throw "SQL script not found: $ScriptPath"
}

$sqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue
if (-not $sqlcmd) {
    throw "sqlcmd was not found in PATH. Please install SQL Server command line tools or run the script from SSMS."
}

Write-Host "Running DB-first setup on server: $Server"
& $sqlcmd.Source -S $Server -i $ScriptPath -b

if ($LASTEXITCODE -ne 0) {
    throw "DB-first setup failed with exit code $LASTEXITCODE"
}

Write-Host "Database setup completed successfully."
