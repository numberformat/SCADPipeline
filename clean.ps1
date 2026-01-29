#!/usr/bin/env pwsh
# Copyright (c) 2026 NOAMi (https://noami.us)
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

if (Test-Path "site") {
  Remove-Item -Recurse -Force "site"
  Write-Host "Removed ./site"
} else {
  Write-Host "No ./site directory to remove"
}
