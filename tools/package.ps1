$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Push-Location $Root
try { & npm test; if ($LASTEXITCODE -ne 0) { throw "Test suite failed with exit code $LASTEXITCODE" } }
finally { Pop-Location }
$Dist = Join-Path $Root "dist"
$Stage = Join-Path $Dist "ForeverDungeonJournal"
if (Test-Path $Stage) { Remove-Item -Recurse -Force $Stage }
New-Item -ItemType Directory -Force $Stage | Out-Null
$Files = @("ForeverDungeonJournal.toc", "Core.lua", "Database.lua", "DataRegistry.lua", "NativeData.lua", "UI.lua", "Options.lua", "README.md", "CHANGELOG.md", "LICENSE")
foreach ($File in $Files) { Copy-Item (Join-Path $Root $File) $Stage }
New-Item -ItemType Directory -Force (Join-Path $Stage "Media") | Out-Null
Copy-Item (Join-Path $Root "Media\Icon.tga") (Join-Path $Stage "Media")
New-Item -ItemType Directory -Force (Join-Path $Stage "docs") | Out-Null
Copy-Item (Join-Path $Root "docs\DATA_PACKS.md") (Join-Path $Stage "docs")
Copy-Item (Join-Path $Root "docs\OSS_PREFLIGHT.md") (Join-Path $Stage "docs")
Copy-Item (Join-Path $Root "docs\DATA_AUTHOR_GUIDE.md") (Join-Path $Stage "docs")
$Zip = Join-Path $Dist "ForeverDungeonJournal-0.2.0-alpha.1.zip"
if (Test-Path $Zip) { Remove-Item -Force $Zip }
Compress-Archive -Path $Stage -DestinationPath $Zip
& (Join-Path $Root "tools\validate-package.ps1") -Zip $Zip
Write-Host "Created $Zip"
