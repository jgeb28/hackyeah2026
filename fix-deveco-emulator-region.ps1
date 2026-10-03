# fix-deveco-emulator-region.ps1
# Sets DevEco Studio region to CN and clears the GRS cache so phone emulators appear.
[CmdletBinding()]
param(
    [string]$Region = 'CN'
)

$ErrorActionPreference = 'Stop'

function Write-Step($m) { Write-Host "[*] $m" }
function Write-Ok($m)   { Write-Host "[+] $m" -ForegroundColor Green }
function Write-Warn2($m){ Write-Host "[!] $m" -ForegroundColor Yellow }
function Write-Err($m)  { Write-Host "[x] $m" -ForegroundColor Red }

if (Get-Process -Name 'devecostudio64','devecostudio','studio64' -ErrorAction SilentlyContinue) {
    Write-Err 'DevEco Studio jest uruchomione. Zamknij je calkowicie i uruchom skrypt ponownie.'
    exit 1
}

$roamingRoot = Join-Path $env:APPDATA 'Huawei'
$localRoot   = Join-Path $env:LOCALAPPDATA 'Huawei'

$configDirs = @()
if (Test-Path $roamingRoot) {
    $configDirs = @(Get-ChildItem $roamingRoot -Directory -Filter 'DevEcoStudio*' -ErrorAction SilentlyContinue)
}
if ($configDirs.Count -eq 0) {
    Write-Err "Nie znaleziono folderu DevEcoStudio* w $roamingRoot"
    exit 1
}

$xml = @"
<application>
    <component name="CountryRegionSetting">
        <countryregion name="$Region"/>
    </component>
</application>
"@

foreach ($dir in $configDirs) {
    Write-Step "DevEco: $($dir.Name)"

    $optionsDir = Join-Path $dir.FullName 'options'
    $regionFile = Join-Path $optionsDir 'country.region.xml'
    if (-not (Test-Path $optionsDir)) { New-Item -ItemType Directory -Path $optionsDir -Force | Out-Null }
    if (Test-Path $regionFile) { Copy-Item $regionFile "$regionFile.bak" -Force }
    [System.IO.File]::WriteAllText($regionFile, $xml, (New-Object System.Text.UTF8Encoding($false)))
    Write-Ok "Region ustawiony na ${Region}: $regionFile"

    $grs = Join-Path $localRoot "$($dir.Name)\caches\grs.json"
    if (Test-Path $grs) {
        Copy-Item $grs "$grs.bak" -Force
        Remove-Item $grs -Force
        Write-Ok "Usunieto cache GRS: $grs"
    }
}

Write-Host ''
Write-Ok 'Gotowe. Uruchom DevEco Studio -> Tools -> Device Manager -> New Emulator.'
Write-Host 'Jesli telefonow nadal brak: wyloguj sie z proxy/VPN, zrestartuj IDE lub komputer.'
