param([Parameter(Mandatory = $true)][string]$Zip)
$ErrorActionPreference = "Stop"
$Expected = @(
    "CHANGELOG.md",
    "Core.lua",
    "Database.lua",
    "DataRegistry.lua",
    "NativeData.lua",
    "ForeverDungeonJournal.toc",
    "LICENSE",
    "Media/Icon.tga",
    "Options.lua",
    "README.md",
    "UI.lua",
    "docs/DATA_PACKS.md",
    "docs/DATA_AUTHOR_GUIDE.md",
    "docs/OSS_PREFLIGHT.md"
) | Sort-Object
$Temp = Join-Path ([IO.Path]::GetTempPath()) ("fdj-package-" + [guid]::NewGuid().ToString("N"))
try {
    Expand-Archive -LiteralPath $Zip -DestinationPath $Temp
    $Root = Join-Path $Temp "ForeverDungeonJournal"
    if (-not (Test-Path -LiteralPath (Join-Path $Root "ForeverDungeonJournal.toc") -PathType Leaf)) {
        throw "Archive does not contain ForeverDungeonJournal/ForeverDungeonJournal.toc"
    }
    $Actual = @(Get-ChildItem -LiteralPath $Root -File -Recurse | ForEach-Object {
        $_.FullName.Substring($Root.Length + 1).Replace("\", "/")
    } | Sort-Object)
    $Difference = Compare-Object -ReferenceObject $Expected -DifferenceObject $Actual
    if ($Difference) {
        throw "Archive allowlist mismatch:`n$($Difference | Out-String)"
    }
    if (Get-ChildItem -LiteralPath $Temp -Recurse -Force | Where-Object { $_.Name -eq "node_modules" -or $_.Name -eq ".git" -or $_.FullName -match "[\\/]dev[\\/]" }) {
        throw "Archive contains a forbidden development path"
    }
    Write-Host "Package integrity passed: $($Actual.Count) allowlisted files; no node_modules, .git, or dev content."
}
finally {
    if (Test-Path -LiteralPath $Temp) { Remove-Item -LiteralPath $Temp -Recurse -Force }
}
