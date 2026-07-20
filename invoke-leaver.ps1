<#
.SYNOPSIS
    One-liner launcher for the Microsoft 365 Leaver Cleanup Tool.

.DESCRIPTION
    Installs the tool into a PERMANENT folder (Desktop\LeaverCleanupTool) and
    launches it there. A permanent folder is used on purpose: this tool creates
    undo files (Restore_*.json), audit logs, and a config file that MUST persist
    between runs — running from a temporary folder would lose your safety net.

    Run with:
    irm https://raw.githubusercontent.com/xnostra/LeaverCleanupTool/main/invoke-leaver.ps1 | iex

.NOTES
    Version: 1.0
    LastModified: 2026-07-20

.LINK
    https://github.com/xnostra/LeaverCleanupTool
#>

$repoRaw    = "https://raw.githubusercontent.com/xnostra/LeaverCleanupTool/main"
$scriptUrl  = "$repoRaw/Disable-RemoveLicenses.ps1"

# Permanent install folder so undo files, logs, and config persist
$installDir = Join-Path ([Environment]::GetFolderPath('Desktop')) "LeaverCleanupTool"
$scriptPath = Join-Path $installDir "Disable-RemoveLicenses.ps1"

Write-Host "Microsoft 365 Leaver Cleanup Tool" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# This tool must NOT run elevated (elevation breaks Microsoft sign-in)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host "This tool must run as a NORMAL user (not Administrator)." -ForegroundColor Red
    Write-Host "Elevated windows break the Microsoft sign-in prompt." -ForegroundColor Red
    Write-Host "Please open a normal (non-admin) PowerShell window and run the one-liner again." -ForegroundColor Yellow
    Read-Host "Press Enter to close"
    return
}

try {
    if (-not (Test-Path $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }

    Write-Host "Installing/updating the tool in:" -ForegroundColor Yellow
    Write-Host "  $installDir" -ForegroundColor Gray
    Write-Host ""

    # Download the latest main script into the permanent folder
    Invoke-RestMethod -Uri $scriptUrl -UseBasicParsing -ErrorAction Stop | Out-File -FilePath $scriptPath -Encoding UTF8 -Force
    Write-Host "Ready. Launching the tool..." -ForegroundColor Green
    Write-Host ""

    # Launch in a fresh STA PowerShell process so:
    #  - the Windows Forms dialogs (file pickers, prompts) work
    #  - $PSScriptRoot resolves to the permanent folder (undo files/logs/config persist)
    Start-Process powershell.exe -ArgumentList @(
        "-NoProfile",
        "-STA",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$scriptPath`""
    )

    Write-Host "The tool has opened in a new window." -ForegroundColor Cyan
    Write-Host "All reports, undo files, and logs are saved in:" -ForegroundColor Gray
    Write-Host "  $installDir" -ForegroundColor Gray
}
catch {
    Write-Host ""
    Write-Host "ERROR: Could not download or launch the tool." -ForegroundColor Red
    Write-Host "URL: $scriptUrl" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Read-Host "Press Enter to close"
}
