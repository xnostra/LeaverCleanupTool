@echo off
REM Creates a clean desktop shortcut ("Leaver Cleanup Tool") with a proper icon.
REM Run this once. You can then launch the tool from the shortcut instead of the .bat.
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$w=New-Object -ComObject WScript.Shell;" ^
  "$s=$w.CreateShortcut([System.IO.Path]::Combine([Environment]::GetFolderPath('Desktop'),'Leaver Cleanup Tool.lnk'));" ^
  "$s.TargetPath=[System.IO.Path]::Combine('%~dp0','Leaver Cleanup Tool.bat');" ^
  "$s.WorkingDirectory='%~dp0';" ^
  "$s.IconLocation=[System.IO.Path]::Combine('%~dp0','leaver-tool.ico');" ^
  "$s.Description='Microsoft 365 Leaver Cleanup Tool';" ^
  "$s.Save();" ^
  "Write-Host 'Shortcut created on your Desktop.' -ForegroundColor Green"
echo.
echo Done. A "Leaver Cleanup Tool" shortcut with an icon is now on your Desktop.
pause
