param(
  [string]$FlutterExe = "C:\Users\Administrator\fvm\default\bin\flutter.bat",
  [string]$IsccExe = "D:\unitPrograms\Inno Setup 6\ISCC.exe",
  [string]$ReleaseTag,
  [string]$OutputBaseFilename,
  [string]$OutputDir,
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pubspecPath = Join-Path $repoRoot "pubspec.yaml"
$releaseDir = Join-Path $repoRoot "build\windows\x64\runner\Release"
$resolvedOutputDir = if ($OutputDir) {
  $OutputDir.Trim()
} else {
  Join-Path $repoRoot "dist\windows-installer"
}
$stagingOutputDir = Join-Path ([System.IO.Path]::GetTempPath()) ("diary-installer\" + [guid]::NewGuid().ToString())
$issPath = Join-Path $repoRoot "windows\installer\diary_setup.iss"

Set-Location $repoRoot

if (-not $ReleaseTag) {
  try {
    $ReleaseTag = (git describe --tags --abbrev=0).Trim()
  } catch {
    $ReleaseTag = ""
  }
}

$pubspecVersionLine = Select-String -Path $pubspecPath -Pattern '^version:\s*(.+)$' | Select-Object -First 1
if (-not $pubspecVersionLine) {
  throw "Unable to read version from pubspec.yaml."
}

$pubspecVersion = ($pubspecVersionLine.Matches[0].Groups[1].Value -split '\+')[0].Trim()
$installerVersion = if ($ReleaseTag) { $ReleaseTag.TrimStart('v') } else { $pubspecVersion }
$resolvedOutputBaseFilename = if ($OutputBaseFilename) {
  $OutputBaseFilename.Trim()
} elseif ($ReleaseTag) {
  "Diary-Setup-$ReleaseTag"
} else {
  "Diary-Setup-v$pubspecVersion"
}

if (-not (Test-Path $FlutterExe)) {
  throw "Flutter executable not found: $FlutterExe"
}

if (-not (Test-Path $IsccExe)) {
  throw "ISCC.exe not found: $IsccExe"
}

if (-not $SkipBuild) {
  & $FlutterExe build windows --release
  if ($LASTEXITCODE -ne 0) {
    throw "flutter build windows --release failed."
  }
}

$appExe = Join-Path $releaseDir "diary_mvp.exe"
if (-not (Test-Path $appExe)) {
  throw "Windows release executable not found: $appExe"
}

New-Item -ItemType Directory -Force $resolvedOutputDir | Out-Null
New-Item -ItemType Directory -Force $stagingOutputDir | Out-Null

& $IsccExe `
  "/DReleaseDir=$releaseDir" `
  "/DOutputDir=$stagingOutputDir" `
  "/DMyAppVersion=$installerVersion" `
  "/DMyOutputBaseFilename=$resolvedOutputBaseFilename" `
  $issPath

if ($LASTEXITCODE -ne 0) {
  throw "ISCC packaging failed."
}

$stagedSetupExe = Join-Path $stagingOutputDir "$resolvedOutputBaseFilename.exe"
if (-not (Test-Path $stagedSetupExe)) {
  throw "Installer was not generated: $stagedSetupExe"
}

$setupExe = Join-Path $resolvedOutputDir "$resolvedOutputBaseFilename.exe"
Copy-Item -Path $stagedSetupExe -Destination $setupExe -Force
Remove-Item -Path $stagingOutputDir -Recurse -Force

Write-Host ""
Write-Host "Installer created successfully:" -ForegroundColor Green
Write-Host $setupExe
