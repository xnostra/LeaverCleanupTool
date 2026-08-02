# Microsoft 365 Leaver Cleanup Tool

A menu-driven PowerShell tool for safely offboarding leavers (students or staff) from Microsoft 365. It disables accounts, removes group/distribution-list/Teams memberships, hides users from the address book, and removes licences. For staff, it preserves email and archives OneDrive files to SharePoint.

Built for schools and organisations that offboard people in batches (e.g., end of term/year) with heavy emphasis on **safety**: dry-run preview, undo files for every run, and automatic protection against touching the wrong accounts.

### What's new in v1.1
- Group-based license removal (see Features below), including licenses assigned via a **nested** group (a group the person belongs to indirectly, through another group)
- When a license-assigning group can't be removed (permissions, or it's synced from on-premises AD), the report now says exactly why instead of a generic "check permissions"
- OneDrive archiving no longer creates duplicate "Name (1)", "file (2).docx" copies if an account gets processed more than once - it reuses the existing archive folder and skips files already copied
- Much faster sign-in checks on large lists (batched instead of one-by-one)
- Auto-detects the real header row in spreadsheets that have a title row above it
- The one-liner launcher now verifies it actually relaunched successfully before trusting it, instead of silently doing nothing on systems that can't drop admin rights

## Quick Start

**Option A — One-liner (installs to `Desktop\LeaverCleanupTool` and launches):**

```powershell
irm https://raw.githubusercontent.com/xnostra/Sherborne-Leaver-Cleanup-Tool/main/invoke-leaver.ps1 | iex
```

> Works from **either a normal or an Administrator** PowerShell window — if it detects admin, it automatically relaunches the tool as your normal user (required for Microsoft sign-in) via a one-off scheduled task. The tool installs into a permanent folder on your Desktop so undo files, logs, and config persist between runs. Re-running the one-liner updates the tool in place.

**Option B — Manual:**

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

✅ **Group-Based License Removal** — If a leaver's license comes from group membership (not assigned directly), the tool detects which group is granting it - checking nested/indirect group membership too - and removes them from that group automatically. If it can't (permissions, or the group is synced from on-premises AD), it tells you exactly why

✅ **No Duplicate OneDrive Archives** — If an account gets processed more than once, the tool reuses the existing archive folder and skips files already copied there, instead of creating "Name (1)", "file (2).docx" duplicates

✅ **Fast on Large Lists** — Sign-in security checks for hundreds of leavers are fetched in batches (up to 20 people per request) instead of one at a time, so a large end-of-year list finishes in a fraction of the time

✅ **Smart Header Detection** — If your spreadsheet has a title row above the real column headers (common in school exports), the tool finds the real header row automatically instead of failing to match anyone

---

## Speed & running Students + Staff side by side

Two things make large lists fast:

- **Batched sign-in checks** — instead of one network request per person, the tool asks Microsoft for up to 20 people's sign-in history at once. This is what actually makes a 300+ person list fast, safely, using Microsoft's own supported batching feature.
- **A 4-hour cache of your tenant's full user list** — shared between runs (and between Student/Staff windows) so you're not re-downloading thousands of accounts every time.

We deliberately did **not** add raw multi-threaded account changes (disabling, license/group removal, mailbox conversion happening for several people at once). Exchange Online only allows a small number of simultaneous connections per admin, and Microsoft will throttle or error out under heavy parallel writes — that would risk partially-completed cleanups, which is worse than a few extra minutes of runtime.

**Want to run Students and Staff at the same time?** Just open two PowerShell windows and run one in each:

```powershell
# Window 1
.\Disable-RemoveLicenses.ps1 -CsvPath .\students.csv -Commit

# Window 2 (at the same time)
.\Disable-RemoveLicenses.ps1 -CsvPath .\staff.csv -StaffMode -Commit
```

This is safe — each window writes its own report, undo file, and log entries. The shared 4-hour user-list cache is written safely (temp file + atomic rename) so one window refreshing it can never corrupt what the other window is reading.

---

## Requirements

- Windows with **Windows PowerShell 5.1** (the built-in version).
- A **Microsoft 365 Global Administrator** account (this is a cloud admin role — not local PC admin).
- Internet access to install modules on first run: `Microsoft.Graph.*`, `ExchangeOnlineManagement` (pinned to 3.4.0), `Microsoft.Online.SharePoint.PowerShell`, `ImportExcel`.

> **Prefer a normal (non-administrator) window.** Elevated windows can break the Microsoft sign-in. The tool detects an elevated window and tries to relaunch itself as your normal user. If your system can't actually drop admin rights (some locked-down or always-elevated setups), it now verifies that before trusting it, and falls back to just running the tool right there instead of silently doing nothing.

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
