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

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

try {
    if (-not (Test-Path $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }

    Write-Host "Installing/updating the tool in:" -ForegroundColor Yellow
    Write-Host "  $installDir" -ForegroundColor Gray
    Write-Host ""

    # Download the latest main script into the permanent folder
    Invoke-RestMethod -Uri $scriptUrl -UseBasicParsing -ErrorAction Stop | Out-File -FilePath $scriptPath -Encoding UTF8 -Force

    $psArgs = "-NoProfile -STA -ExecutionPolicy Bypass -File `"$scriptPath`""

    if ($isAdmin) {
        # PowerShell is elevated, but this tool's Microsoft sign-in breaks under admin.
        # Force-launch the tool as the NORMAL interactive user via a one-off scheduled task
        # (a child process would otherwise inherit admin - a scheduled task at "Limited"
        #  run level is the reliable way to drop back to normal rights).
        Write-Host "Detected an Administrator PowerShell." -ForegroundColor Yellow
        Write-Host "Force-launching the tool as your NORMAL user (so Microsoft sign-in works)..." -ForegroundColor Yellow
        Write-Host ""

        $launched = $false
        try {
            $me     = [Security.Principal.WindowsIdentity]::GetCurrent().Name
            $action = New-ScheduledTaskAction -Execute (Join-Path $PSHOME 'powershell.exe') -Argument $psArgs -WorkingDirectory $installDir
            $princ  = New-ScheduledTaskPrincipal -UserId $me -LogonType Interactive -RunLevel Limited
            $task   = New-ScheduledTask -Action $action -Principal $princ
            $tn     = 'LeaverCleanup_LaunchAsUser'
            Register-ScheduledTask -TaskName $tn -InputObject $task -Force -ErrorAction Stop | Out-Null
            Start-ScheduledTask -TaskName $tn -ErrorAction Stop
            Start-Sleep -Seconds 2
            Unregister-ScheduledTask -TaskName $tn -Confirm:$false -ErrorAction SilentlyContinue
            $launched = $true
        } catch {
            Write-Host "Scheduled-task launch failed: $($_.Exception.Message)" -ForegroundColor Red
        }

        if (-not $launched) {
            # Fallback: launch via explorer.exe, which always runs at normal (medium) integrity
            Write-Host "Falling back to explorer launch..." -ForegroundColor Yellow
            Start-Process "explorer.exe" -ArgumentList "`"$scriptPath`""
        }
    }
    else {
        # Already a normal user - launch directly in a fresh STA window
        Start-Process powershell.exe -ArgumentList $psArgs
    }

    Write-Host "The tool is opening in a new window (as your normal user)." -ForegroundColor Green
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
