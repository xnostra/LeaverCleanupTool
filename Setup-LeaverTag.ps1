# ONE-TIME SETUP - run this yourself: .\Setup-LeaverTag.ps1
#
# Updates the "All Users" dynamic group rule to exclude anyone tagged with
# extensionAttribute15 = "Leaver" - the tag Disable-RemoveLicenses.ps1 now stamps on every
# account it disables. No app registration needed - extensionAttribute15 is a built-in
# attribute every tenant already has, writable with the same permissions the tool already uses.
#
# (Two earlier approaches were tried and rejected: custom security attributes aren't usable
# in dynamic group rules without a Microsoft Entra ID Governance license, and a custom
# directory schema extension can only be WRITTEN by its owning app, not via delegated
# Microsoft Graph PowerShell sign-in. extensionAttribute15 has neither restriction.)

Import-Module Microsoft.Graph.Groups -ErrorAction Stop

Connect-MgGraph -Scopes "Group.ReadWrite.All" -NoWelcome

$tagValue = "Leaver"

Write-Host "`n=== Update 'All Users' dynamic group rule ===" -ForegroundColor Cyan
$grp = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq 'All Users'&`$select=id,displayName,membershipRule"
$g = $grp.value[0]
if (-not $g) { Write-Host "Group 'All Users' not found." -ForegroundColor Red; exit 1 }

Write-Host "Current rule: $($g.membershipRule)"
$currentRule = $g.membershipRule
if ([string]::IsNullOrWhiteSpace($currentRule) -or $currentRule -eq "All Users") {
    $baseRule = "(user.objectId -ne null)"
} elseif ($currentRule -match [regex]::Escape('extension_45f2337b10814a028df84789bf9b4366_IsLeaver')) {
    # undo the previous (non-working) schema-extension attempt cleanly instead of nesting it
    $baseRule = "(user.objectId -ne null)"
} else {
    $baseRule = "($currentRule)"
}
$newRule = "$baseRule and not (user.extensionAttribute15 -eq `"$tagValue`")"
Write-Host "Proposed new rule: $newRule" -ForegroundColor Yellow

$confirm = Read-Host "`nApply this rule to 'All Users'? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "Cancelled - group rule NOT changed." -ForegroundColor Red
    exit 0
}

try {
    $ruleBody = @{ membershipRule = $newRule } | ConvertTo-Json
    Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/groups/$($g.id)" -Body $ruleBody -ContentType "application/json" -ErrorAction Stop
    Write-Host "`nDone. Rule applied." -ForegroundColor Green
    Write-Host "From now on, any account the Leaver Cleanup Tool disables (that isn't still synced from" -ForegroundColor Green
    Write-Host "local AD) will be tagged extensionAttribute15 = Leaver and drop out of All Users." -ForegroundColor Green
} catch {
    Write-Host "`nFAILED to apply rule." -ForegroundColor Red
    Write-Host "Exception: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) { Write-Host "Response body: $($_.ErrorDetails.Message)" -ForegroundColor Red }
    Write-Host "Group rule NOT changed." -ForegroundColor Red
}
