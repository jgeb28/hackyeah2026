#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Build the Guardian app HAP (the `entry` module only — not the mocks).

.DESCRIPTION
  Ensures the on-device models are present (downloads them from Hugging Face via
  tools/fetch_model.py when missing), then runs hvigor's `assembleHap` for the
  `entry` module of HuwaweiChallenge.

.PARAMETER DevEco
  DevEco Studio install root. Defaults to $env:DEVECO_HOME, then the usual
  Windows location.

.PARAMETER JavaHome
  JDK 17 home (the packaging step needs `java`). Defaults to $env:JAVA_HOME, then
  DevEco's bundled jbr.

.PARAMETER Clean
  Run hvigor `clean` before building.

.PARAMETER SkipFetch
  Do not download models even if they are missing.

.EXAMPLE
  pwsh -File .\build.ps1
#>
param(
  [string]$DevEco = $env:DEVECO_HOME,
  [string]$JavaHome = $env:JAVA_HOME,
  [switch]$Clean,
  [switch]$SkipFetch
)
$ErrorActionPreference = 'Stop'
$Root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$Project = Join-Path $Root 'HuwaweiChallenge'
$Rawfile = Join-Path $Project 'entry\src\main\resources\rawfile'

function Find-DevEco([string]$hint) {
  $cands = @()
  if ($hint) { $cands += $hint }
  $cands += @(
    (Join-Path ${env:ProgramFiles} 'Huawei\DevEco Studio'),
    'C:\Program Files\Huawei\DevEco Studio'
  )
  foreach ($c in $cands) {
    if ($c -and (Test-Path (Join-Path $c 'tools\hvigor\bin\hvigorw.js'))) { return $c }
  }
  return ''
}

$DevEco = Find-DevEco $DevEco
if (-not $DevEco) {
  throw "DevEco Studio not found. Set DEVECO_HOME or pass -DevEco <path>."
}
$hvigor = Join-Path $DevEco 'tools\hvigor\bin\hvigorw.js'
$nodeBundled = Join-Path $DevEco 'tools\node\node.exe'
$node = if (Test-Path $nodeBundled) { $nodeBundled } else { (Get-Command node -ErrorAction SilentlyContinue).Source }
if (-not $node) { throw "node not found (expected $nodeBundled or node on PATH)." }

if (-not $JavaHome) {
  $jbr = Join-Path $DevEco 'jbr'
  if (Test-Path $jbr) { $JavaHome = $jbr }
}
if ($JavaHome -and (Test-Path $JavaHome)) {
  $env:JAVA_HOME = $JavaHome
  $env:PATH = "$JavaHome\bin;$env:PATH"
}

$ms = Join-Path $Rawfile 'laya_en_w8_s256.ms'
if (-not (Test-Path $ms) -and -not $SkipFetch) {
  Write-Host '[*] on-device models missing; fetching from Hugging Face...'
  $py = (Get-Command python -ErrorAction SilentlyContinue).Source
  if (-not $py) { $py = (Get-Command python3 -ErrorAction SilentlyContinue).Source }
  if (-not $py) { throw 'python not found; cannot fetch models (or pass -SkipFetch).' }
  & $py (Join-Path $Root 'tools\fetch_model.py') --out-dir $Root
}

$env:DEVECO_SDK_HOME = Join-Path $DevEco 'sdk'
$env:NODE_HOME = Join-Path $DevEco 'tools\node'
$env:PATH = "$(Join-Path $DevEco 'tools\node');$(Join-Path $DevEco 'tools\ohpm\bin');$env:PATH"

Write-Host "[*] building entry (DevEco: $DevEco)"
Push-Location $Project
try {
  if ($Clean) { & $node $hvigor --mode module -p module=entry@default -p product=default clean --no-daemon }
  & $node $hvigor --mode module -p module=entry@default -p product=default `
      -p requiredDeviceType=phone assembleHap --no-daemon
} finally { Pop-Location }

$out = Join-Path $Project 'entry\build\default\outputs\default'
Write-Host "[+] done. HAP in $out"
Get-ChildItem $out -Filter '*.hap' -ErrorAction SilentlyContinue |
  ForEach-Object { "{0,-34} {1,8:N1} MB" -f $_.Name, ($_.Length / 1MB) }
