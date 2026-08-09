# Run this yourself in a normal PowerShell window: .\Trace-DynamicGroupSource.ps1
# Read-only: no writes, no removals.

Import-Module Microsoft.Graph.Groups -ErrorAction Stop
Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop
Import-Module Microsoft.Graph.Users -ErrorAction Stop

Connect-MgGraph -Scopes "User.ReadWrite.All","Organization.Read.All","AuditLog.Read.All","Directory.Read.All","GroupMember.ReadWrite.All" -NoWelcome

Write-Host "`n=== SCHEMA EXTENSION OWNER APP (fe217466-5583-431c-9531-14ff7268b7b3) ===" -ForegroundColor Cyan
try {
    $sp = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq 'fe217466-5583-431c-9531-14ff7268b7b3'"
    $sp.value | ConvertTo-Json -Depth 5
} catch { Write-Host "lookup failed: $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Host "`n=== SAMPLE 'ALL TEACHERS' MEMBERS - SYNC SOURCE + EXTENSION VALUE ===" -ForegroundColor Cyan
try {
    $grp = Get-MgGroup -Filter "displayName eq 'All Teachers'" -Property "id"
    $members = Get-MgGroupMember -GroupId $grp.Id -Top 3
    foreach ($m in $members) {
        $u = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$($m.Id)?`$select=displayName,userPrincipalName,onPremisesSyncEnabled,onPremisesDistinguishedName,extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType"
        $u | ConvertTo-Json -Depth 5
        Write-Host "---"
    }
} catch { Write-Host "sample user lookup failed: $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Host "`n=== DONE - paste everything above back to Claude ===" -ForegroundColor Green
