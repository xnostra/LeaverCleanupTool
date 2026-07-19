# Microsoft 365 Leaver Cleanup Tool

A menu-driven PowerShell tool for safely offboarding leavers (students or staff) from Microsoft 365. It disables accounts, removes group / distribution-list / Teams memberships, hides users from the address book, and removes licences — and for staff it preserves email (converts the mailbox to a free shared mailbox) and archives OneDrive files to SharePoint.

Built for schools/organisations that offboard people in batches (e.g. end of term/year), with heavy emphasis on **safety**: preview before commit, an undo file for every run, and automatic protection against touching the wrong accounts.

---

## Features

- **Dry run first** — preview any bulk cleanup and get a colour-coded Excel report; nothing changes until you commit.
- **Students vs. Staff modes** — student runs automatically refuse to touch anything that looks like a staff account; staff runs preserve email and archive OneDrive.
- **Smart matching** — matches by email, then falls back to name (handles missing/old emails, word-order differences, middle names, spelling variants).
- **Recycled-address protection** — detects when a leaver's old email now belongs to a *new* person (account created after they left, or a different name) and skips it.
- **Recently-active + sign-in checks** — skips accounts used recently; flags sign-ins from outside your country or repeated failed logins.
- **Hybrid aware** — detects accounts synced from on-premises Active Directory and tells you which steps must be done in local AD instead of the cloud.
- **Undo** — every commit writes a `Restore_*.json`; the RESTORE menu puts any account back exactly as it was.
- **Purge** — deletes accounts that have been disabled + unlicensed + inactive for years (shared mailboxes protected; deletions restorable for 30 days).
- **Reports & logs** — formatted Excel report per run, plus a running monthly log.
- **Self-installing** — installs the required modules on first run; drops its own admin rights if launched elevated.

---

## Requirements

- Windows with **Windows PowerShell 5.1** (the built-in version).
- A **Microsoft 365 Global Administrator** account (this is a cloud admin role — not local PC admin).
- Internet access to install modules on first run: `Microsoft.Graph.*`, `ExchangeOnlineManagement` (pinned to 3.4.0), `Microsoft.Online.SharePoint.PowerShell`, `ImportExcel`.

> **Do not run as administrator.** Elevated windows break the Microsoft sign-in. The tool detects this and relaunches itself as a normal user.

---

## Quick start

1. Download the files (or clone the repo).
2. *(Optional)* double-click **`Create Shortcut.bat`** to get a desktop shortcut with an icon.
3. Double-click **`Leaver Cleanup Tool.bat`**.
4. Sign in with your global admin account when prompted.
5. Choose **DRY RUN**, pick your leaver list, review the Excel report, then **COMMIT**.

### Leaver list format

Any CSV or Excel file. Column names are auto-detected. At minimum an **email** column; **name** and **leaving date** columns make the safety checks stronger.

```
Email,Name,LeavingDate
jsmith@example.org,John Smith,2024-06-30
```

iSAMS-style headers (`Pupil Email Address`, `Full Name`, `Leaving Date`) are also recognised automatically.

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
