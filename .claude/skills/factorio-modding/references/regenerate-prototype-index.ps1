# Regenerates references/prototype-index.md from a prototype-api.json
# (download from https://lua-api.factorio.com/latest/prototype-api.json).
#
# Usage: .\regenerate-prototype-index.ps1 -ApiJson path\to\prototype-api.json
param(
    [Parameter(Mandatory = $true)][string]$ApiJson,
    [string]$OutFile = (Join-Path $PSScriptRoot "prototype-index.md")
)

$json = Get-Content $ApiJson -Raw | ConvertFrom-Json
$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine("# Factorio 2.x Prototype Index")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("Generated from prototype-api.json (api_version $($json.api_version), game $($json.application_version)).")
$null = $sb.AppendLine("Entries marked **[NO DESC]** have blank descriptions in the API.")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("| Prototype class | typename | Description |")
$null = $sb.AppendLine("|---|---|---|")
foreach ($p in $json.prototypes | Sort-Object name) {
    $desc = [regex]::Replace($p.description.Trim(), '\[([^\]]+)\]\([^)]+\)', '$1')
    $first = ($desc -split '\.')[0].Trim()
    $abstractTag = if ($p.abstract -eq $true) { " *(abstract)*" } else { "" }
    $tn = if ($p.typename) { $p.typename } else { "*(abstract)*" }
    if (-not $desc) { $null = $sb.AppendLine("| $($p.name)$abstractTag | $tn | **[NO DESC]** |") }
    else            { $null = $sb.AppendLine("| $($p.name)$abstractTag | $tn | $first |") }
}
$null = $sb.AppendLine("")
$null = $sb.AppendLine("---")
$null = $sb.AppendLine("*Abstract prototypes are base types only — not used directly in data:extend.*")
[System.IO.File]::WriteAllText($OutFile, $sb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host "Wrote $OutFile"
