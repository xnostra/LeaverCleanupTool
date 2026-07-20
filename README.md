# Microsoft 365 Leaver Cleanup Tool

A menu-driven PowerShell tool for safely offboarding leavers (students or staff) from Microsoft 365. It disables accounts, removes group/distribution-list/Teams memberships, hides users from the address book, and removes licences. For staff, it preserves email and archives OneDrive files to SharePoint.

Built for schools and organisations that offboard people in batches (e.g., end of term/year) with heavy emphasis on **safety**: dry-run preview, undo files for every run, and automatic protection against touching the wrong accounts.

## Quick Start

1. **Download**: Clone this repo or download the files
2. **Run**: Double-click **`Leaver Cleanup Tool.bat`**
3. **Sign in**: Use your Microsoft 365 Global Administrator account
4. **Dry Run**: Preview changes and review the Excel report
5. **Commit**: Once satisfied, commit the changes

For command-line execution:
```powershell
.\Disable-RemoveLicenses.ps1 -CsvPath .\leavers.csv -SkipIfActiveWithinDays 60
```

---

## Features

✅ **Dry Run First** — Preview bulk cleanup with colour-coded Excel reports; nothing changes until you commit

✅ **Students vs. Staff Modes** — Student runs refuse to touch staff accounts; staff runs preserve email and archive OneDrive

✅ **Smart Matching** — Matches by email, falls back to name; handles missing emails, word-order differences, middle names, and spelling variants

✅ **Recycled-Address Protection** — Detects when a leaver's old email now belongs to a new person and skips it

✅ **Activity & Sign-in Checks** — Skips recently-used accounts; flags suspicious sign-ins (outside your country, repeated failures)

✅ **Hybrid Aware** — Detects on-premises AD synced accounts; tells you which steps must be done locally

✅ **Undo Capability** — Every commit writes a `Restore_*.json` file; restore any account to its previous state

✅ **Purge Function** — Safely deletes disabled, unlicensed, inactive accounts (shared mailboxes protected; 30-day restore window)

✅ **Reports & Audit Logs** — Formatted Excel reports per run plus a running monthly log for compliance

✅ **Self-Installing** — Installs required modules on first run; auto-detects and handles elevated windows

---

## Requirements

- Windows with **Windows PowerShell 5.1** (the built-in version).
- A **Microsoft 365 Global Administrator** account (this is a cloud admin role — not local PC admin).
- Internet access to install modules on first run: `Microsoft.Graph.*`, `ExchangeOnlineManagement` (pinned to 3.4.0), `Microsoft.Online.SharePoint.PowerShell`, `ImportExcel`.

> **Do not run as administrator.** Elevated windows break the Microsoft sign-in. The tool detects this and relaunches itself as a normal user.

---

## Setup & First Run

1. **Download** the files (or clone the repo)
2. *(Optional)* Double-click **`Create Shortcut.bat`** for a desktop shortcut with icon
3. Double-click **`Leaver Cleanup Tool.bat`**
4. Sign in with your Microsoft 365 Global Administrator account
5. **DRY RUN** — Select your leaver list, review the Excel report
6. **COMMIT** — Once satisfied, commit the changes

The tool installs required modules automatically on first run.

### Leaver List Format

Supports CSV or Excel files. Column names are auto-detected. At minimum: **email** column. Add **name** and **leaving date** for stronger safety checks.

**CSV Example:**
```csv
Email,Name,LeavingDate
jsmith@example.org,John Smith,2024-06-30
```

**Supported Headers:**
- Standard: `Email`, `Name`, `LeavingDate`
- iSAMS-style: `Pupil Email Address`, `Full Name`, `Leaving Date`

---

## Configuration

Open `Disable-RemoveLicenses.ps1` and set these near the top if you want defaults:

- **`$SafeCountries`** (param, default `@('QA')`) — sign-ins from these ISO country codes are treated as normal; anything else is flagged. Change `QA` to your country.
- **`ArchiveSiteUrl`** — the SharePoint site leavers' OneDrive files are copied into. Left blank by default; the tool asks for it on the first staff run and remembers it. Example: `https://yourorg.sharepoint.com/sites/StaffLeaversArchive`.
- Banner text — change `Your Organisation  -  IT Department` to your name.

You can also pass options on the command line, e.g.:

```powershell
.\Disable-RemoveLicenses.ps1 -CsvPath .\leavers.csv -SkipIfActiveWithinDays 60          # dry run
.\Disable-RemoveLicenses.ps1 -CsvPath .\leavers.csv -SkipIfActiveWithinDays 60 -Commit   # for real
.\Disable-RemoveLicenses.ps1 -CsvPath .\staff.csv   -StaffMode -Commit                   # staff (preserve email + archive)
```

---

## On-premises (hybrid) note

If some accounts are synced from a local Active Directory, the tool still does the cloud-safe steps (**licence removal, mailbox → shared, OneDrive archive**), but **disable, hide and group changes for those accounts must be done in your local AD** — doing them only in the cloud is reverted at the next sync. The tool labels each account "Managed in: On-premises AD" or "Cloud" so you know.

---

## Files the tool creates (git-ignored)

| File | Purpose |
|---|---|
| `result_* / COMMITTED_result_*` | Report from each run (Excel + CSV) |
| `Restore_*.json` | Undo file — keep these |
| `Log_YYYYMM.log` | Running history of all actions |
| `PurgeCandidates_*.csv` | List reviewed before any deletion |

These contain real names/accounts and are excluded by `.gitignore` — do not commit them.

---

## Safety & disclaimer

This tool disables accounts and removes licences. Always run a **dry run** first, review the report, and keep the `Restore_*.json` files. Provided as-is with no warranty; test in your own environment before relying on it. You are responsible for changes made in your tenant.

## License

MIT — see `LICENSE`.
