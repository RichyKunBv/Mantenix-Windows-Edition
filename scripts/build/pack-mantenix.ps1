param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [string]$BatchPath
)

$ErrorActionPreference = 'Stop'

$root = Resolve-Path $RepositoryRoot
$iconPath = Join-Path $root 'icon.ico'
$outPath = Join-Path $root 'MantenixW.exe'

$batchCandidates = @()
if ($BatchPath) {
    $batchCandidates += $BatchPath
}
$batchCandidates += @(
    (Join-Path $root 'MantenixWforEXE.bat'),
    (Join-Path $root 'MantenixWbeta.bat'),
    (Join-Path $root 'MantenixW.bat')
)

$batPath = $null
foreach ($candidate in $batchCandidates) {
    if ($candidate -and (Test-Path $candidate)) {
        $batPath = (Resolve-Path $candidate).Path
        break
    }
}

if (-not $batPath) {
    throw "No se encontró un batch válido para empaquetar en $root"
}

if (-not (Test-Path $iconPath)) {
    throw "No se encontró el icono: $iconPath"
}

$versionMatch = Select-String -Path $batPath -Pattern '^\s*set\s+"AppVersion=(?<version>[^\"]+)"' | Select-Object -First 1
$AppVersion = if ($versionMatch) { $versionMatch.Matches[0].Groups['version'].Value.Trim() } else { '0.0.0' }
$AuthorName = 'RichyKunBv'

$batToExe = Get-Command 'bat-to-exe' -ErrorAction SilentlyContinue
if (-not $batToExe) {
    $batToExe = Get-Command 'bat-to-exe-converter' -ErrorAction SilentlyContinue
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

if ($tool) {
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
}
else {
    $dotnet = Get-Command 'dotnet' -ErrorAction SilentlyContinue
    if (-not $dotnet) {
        throw 'No se pudo localizar Bat To Exe Converter ni dotnet en el sistema.'
    }

    $launcherProjectDir = Join-Path $workDir 'launcher'
    New-Item -ItemType Directory -Path $launcherProjectDir -Force | Out-Null

    $launcherCsproj = @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <AssemblyName>MantenixW</AssemblyName>
    <UseAppHost>true</UseAppHost>
    <PublishSingleFile>true</PublishSingleFile>
    <SelfContained>false</SelfContained>
    <RuntimeIdentifier>win-x64</RuntimeIdentifier>
  </PropertyGroup>
</Project>
'@
    Set-Content -Path (Join-Path $launcherProjectDir 'MantenixW.csproj') -Value $launcherCsproj -Encoding UTF8

    $launcherSource = @'
using System;
using System.Diagnostics;
using System.IO;

internal static class Program
{
    private static int Main(string[] args)
    {
        string batchPath = @"__BATCH_PATH__";
        if (!File.Exists(batchPath))
        {
            Console.Error.WriteLine($"No se encontró el archivo por lotes: {batchPath}");
            return 1;
        }

        var startInfo = new ProcessStartInfo
        {
            FileName = "cmd.exe",
            Arguments = $"/c \"{batchPath}\"",
            WorkingDirectory = Path.GetDirectoryName(batchPath) ?? Environment.CurrentDirectory,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        try
        {
            using var process = Process.Start(startInfo);
            if (process is null)
            {
                return 1;
            }

            process.WaitForExit();
            return process.ExitCode;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine(ex.Message);
            return 1;
        }
    }
}
'@
    $launcherSource = $launcherSource.Replace('__BATCH_PATH__', $batTemp)
    Set-Content -Path (Join-Path $launcherProjectDir 'Program.cs') -Value $launcherSource -Encoding UTF8

    $publishDir = Join-Path $workDir 'publish'
    New-Item -ItemType Directory -Path $publishDir -Force | Out-Null

    Push-Location $launcherProjectDir
    try {
        & $dotnet publish -c Release -r win-x64 -p:PublishSingleFile=true -p:UseAppHost=true -p:SelfContained=false -o $publishDir
        if ($LASTEXITCODE -ne 0) {
            throw "dotnet publish terminó con código de salida $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }

    $generatedFiles = @(Get-ChildItem -Path $workDir -Recurse -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
    Write-Host "Archivos generados por dotnet publish:"
    foreach ($file in $generatedFiles) {
        Write-Host " - $file"
    }

    $fallbackExe = $null
    $candidatePaths = @(
        (Join-Path $publishDir 'MantenixW.exe'),
        (Join-Path $publishDir 'MantenixW'),
        (Join-Path $publishDir 'MantenixWLauncher.exe'),
        (Join-Path $publishDir 'MantenixWLauncher'),
        (Join-Path $launcherProjectDir 'bin/Release/net8.0/win-x64/publish/MantenixW.exe'),
        (Join-Path $launcherProjectDir 'bin/Release/net8.0/win-x64/publish/MantenixW'),
        (Join-Path $launcherProjectDir 'bin/Release/net8.0/win-x64/publish/MantenixWLauncher.exe'),
        (Join-Path $launcherProjectDir 'bin/Release/net8.0/win-x64/publish/MantenixWLauncher')
    )

    foreach ($candidate in $candidatePaths) {
        if ($candidate -and (Test-Path $candidate)) {
            $fallbackExe = $candidate
            break
        }
    }

    if (-not $fallbackExe) {
        $fallbackExe = @(Get-ChildItem -Path $workDir -Recurse -File -Filter '*.exe' -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match 'MantenixW|MantenixWLauncher' } |
            Select-Object -ExpandProperty FullName -First 1)
    }

    if (-not $fallbackExe) {
        throw "No se pudo generar el ejecutable alternativo con dotnet. Archivos generados: $($generatedFiles -join ', ')"
    }

    Copy-Item $fallbackExe $outPath -Force
}

$rcedit = Get-Command 'rcedit' -ErrorAction SilentlyContinue
if (-not $rcedit) {
    $choco = Get-Command 'choco' -ErrorAction SilentlyContinue
    if ($choco) {
        try {
            & choco install rcedit -y --no-progress | Out-Null
            $rcedit = Get-Command 'rcedit' -ErrorAction SilentlyContinue
        }
        catch {
            Write-Warning "No se pudo instalar rcedit: $($_.Exception.Message)"
        }
    }
}

if ($rcedit) {
    & $rcedit $outPath --set-icon $iconPath --set-version-string FileDescription 'MantenixW' --set-version-string ProductName 'MantenixW' --set-version-string CompanyName $AuthorName --set-version-string LegalCopyright "© $AuthorName" --set-version-string FileVersion $AppVersion --set-version-string ProductVersion $AppVersion
}

Remove-Item $workDir -Recurse -Force
Write-Host "Ejecutable generado: $outPath"
Write-Host "Versión aplicada: $AppVersion"
Write-Host "Autor aplicado: $AuthorName"
