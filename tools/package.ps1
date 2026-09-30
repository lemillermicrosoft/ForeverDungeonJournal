$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
node (Join-Path $Root "tools\validate.js")
$Dist = Join-Path $Root "dist"
$Stage = Join-Path $Dist "ForeverDungeonJournal"
if (Test-Path $Stage) { Remove-Item -Recurse -Force $Stage }
New-Item -ItemType Directory -Force $Stage | Out-Null
$Files = @("ForeverDungeonJournal.toc", "Core.lua", "Database.lua", "DataRegistry.lua", "UI.lua", "Options.lua", "README.md", "LICENSE")
foreach ($File in $Files) { Copy-Item (Join-Path $Root $File) $Stage }
New-Item -ItemType Directory -Force (Join-Path $Stage "docs") | Out-Null
Copy-Item (Join-Path $Root "docs\DATA_PACKS.md") (Join-Path $Stage "docs")
Copy-Item (Join-Path $Root "docs\OSS_PREFLIGHT.md") (Join-Path $Stage "docs")
$Zip = Join-Path $Dist "ForeverDungeonJournal-0.1.0-alpha.zip"
if (Test-Path $Zip) { Remove-Item -Force $Zip }
Compress-Archive -Path $Stage -DestinationPath $Zip
Write-Host "Created $Zip"
