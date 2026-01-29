#!/usr/bin/env pwsh
# Copyright (c) 2026 NOAMi (https://noami.us)
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  Write-Error "ERROR: docker not found. Install Docker Desktop and try again."
  exit 1
}

$image = $env:OPENSCAD_DOCKER_IMAGE
if ([string]::IsNullOrWhiteSpace($image)) {
  $image = "openscad/openscad:bookworm"
}

$platform = $env:OPENSCAD_DOCKER_PLATFORM
if ([string]::IsNullOrWhiteSpace($platform)) {
  if ($IsMacOS) {
    $arch = (& uname -m).Trim()
    if ($arch -eq "arm64" -or $arch -eq "aarch64") {
      $platform = "linux/amd64"
    }
  }
}

$mount = "$(Get-Location):/workspace"
$userArgs = @()
if (-not $IsWindows) {
  $uid = & id -u
  $gid = & id -g
  $userArgs = @("--user", "$uid:$gid")
}

$platformArgs = @()
if (-not [string]::IsNullOrWhiteSpace($platform)) {
  $platformArgs = @("--platform", $platform)
}

& docker run --rm @userArgs @platformArgs `
  -v $mount `
  -w /workspace `
  $image `
  bash /workspace/scripts/docker-build.sh
