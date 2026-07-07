param(
    [string]$RepositoryRoot = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

$root = Resolve-Path $RepositoryRoot
$batPath = Join-Path $root 'MantenixWforEXE.bat'
$iconPath = Join-Path $root 'icon.ico'
$outPath = Join-Path $root 'MantenixW.exe'

if (-not (Test-Path $batPath)) {
    throw "No se encontró el batch: $batPath"
}

if (-not (Test-Path $iconPath)) {
    throw "No se encontró el icono: $iconPath"
}

$batToExe = Get-Command 'bat-to-exe' -ErrorAction SilentlyContinue
if (-not $batToExe) {
    $batToExe = Get-Command 'bat-to-exe-converter' -ErrorAction SilentlyContinue
}

if (-not $batToExe) {
    $choco = Get-Command 'choco' -ErrorAction SilentlyContinue
    if ($choco) {
        & choco install bat-to-exe-converter -y --no-progress
    }
}

$tool = $null
$possiblePaths = @(
    'C:\Program Files\Bat To Exe Converter\bat-to-exe.exe',
    'C:\Program Files (x86)\Bat To Exe Converter\bat-to-exe.exe',
    'C:\Program Files\Bat To Exe Converter\Bat To Exe Converter.exe',
    'C:\Program Files (x86)\Bat To Exe Converter\Bat To Exe Converter.exe'
)

foreach ($p in $possiblePaths) {
    if (Test-Path $p) {
        $tool = $p
        break
    }
}

if (-not $tool) {
    throw 'No se pudo localizar Bat To Exe Converter en el sistema.'
}

$workDir = Join-Path $root '.tmp-mantenix-pack'
if (Test-Path $workDir) {
    Remove-Item $workDir -Recurse -Force
}
New-Item -ItemType Directory -Path $workDir -Force | Out-Null

$stub = @'
@echo off
setlocal
cd /d "%~dp0"
start "" "%~dp0MantenixWforEXE.bat"
exit /b 0
'@

Set-Content -Path (Join-Path $workDir 'launcher.cmd') -Value $stub -Encoding Ascii

$manifest = @'
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">
    <security>
      <requestedPrivileges>
        <requestedExecutionLevel level="requireAdministrator" uiAccess="false" />
      </requestedPrivileges>
    </security>
  </trustInfo>
</assembly>
'@
Set-Content -Path (Join-Path $workDir 'app.manifest') -Value $manifest -Encoding UTF8

$batContent = Get-Content $batPath -Raw -Encoding Ascii
$batTemp = Join-Path $workDir 'MantenixWforEXE.bat'
Set-Content -Path $batTemp -Value $batContent -Encoding Ascii

$argList = @(
    '/bat', $batTemp,
    '/exe', $outPath,
    '/icon', $iconPath,
    '/x86',
    '/nopause',
    '/silent'
)

& $tool @argList

if (-not (Test-Path $outPath)) {
    throw "El proceso no generó $outPath"
}

Remove-Item $workDir -Recurse -Force
Write-Host "Ejecutable generado: $outPath"
