# Create Junction Script Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a PowerShell command that creates a junction in the current directory from either an explicit source folder or the single folder copied in Windows File Explorer.

**Architecture:** Keep the command in one repository-style PowerShell script. Separate clipboard access, input selection, path validation, and junction creation into functions so all deterministic behavior is testable without changing the live clipboard.

**Tech Stack:** PowerShell 5.1+, `System.Windows.Forms.Clipboard`, PowerShell runspaces, Pester 3.4+

## Global Constraints

- `-Source` overrides clipboard input.
- With no `-Source`, the clipboard must contain exactly one folder.
- The junction is created under the process current working directory with the source folder's leaf name.
- Existing destinations are never deleted or replaced.
- The implementation has no runtime dependencies beyond Windows PowerShell/.NET components.

---

### Task 1: Tested junction command

**Files:**
- Create: `create-junction.ps1`
- Create: `create-junction.Tests.ps1`

**Interfaces:**
- Produces: `Resolve-ClipboardSourcePath -ClipboardItems <object[]> -> string`
- Produces: `Get-ClipboardFolderPaths -> string[]`
- Produces: `New-RepositoryJunction -Source <string> [-DestinationRoot <string>] -> DirectoryInfo`
- Produces: command entry point `create-junction.ps1 [-Source <string>]`

- [x] **Step 1: Write failing tests for source selection and safety**

Create `create-junction.Tests.ps1`, dot-source `create-junction.ps1`, and add Pester cases that assert:

```powershell
function Get-ThrownMessage {
    param([scriptblock]$Operation)

    try { & $Operation; return $null }
    catch { return $_.Exception.Message }
}

Resolve-ClipboardSourcePath -ClipboardItems @('D:\Repos\Payment') | Should Be 'D:\Repos\Payment'
Get-ThrownMessage { Resolve-ClipboardSourcePath -ClipboardItems @() } | Should Match 'exactly one'
Get-ThrownMessage { Resolve-ClipboardSourcePath -ClipboardItems @('D:\One', 'D:\Two') } | Should Match 'exactly one'
```

Use Pester's `$TestDrive` to create a real source and destination root. Assert that `New-RepositoryJunction` creates `<destination-root>\<source-name>`, reports `LinkType` as `Junction`, and exposes a marker file from the source. Add separate cases proving a missing source and an occupied destination throw without deleting existing content.

- [x] **Step 2: Run tests and verify the missing script causes RED**

Run:

```powershell
Invoke-Pester .\create-junction.Tests.ps1
```

Expected: FAIL because `create-junction.ps1` and its functions do not exist.

- [x] **Step 3: Implement the minimal script**

Create `create-junction.ps1` with an optional positional `-Source` parameter. Implement:

```powershell
function Resolve-ClipboardSourcePath {
    param([AllowEmptyCollection()][object[]]$ClipboardItems)

    $items = @($ClipboardItems)
    if ($items.Count -ne 1) {
        throw "Clipboard must contain exactly one copied folder; found $($items.Count)."
    }

    [string]$items[0]
}
```

Implement `Get-ClipboardFolderPaths` by creating an STA runspace, loading `System.Windows.Forms`, and invoking `[System.Windows.Forms.Clipboard]::GetFileDropList()`. Dispose both the `PowerShell` instance and runspace in `finally`.

Implement junction creation with these operations:

```powershell
$sourceItem = Get-Item -LiteralPath $Source -Force -ErrorAction Stop
if (-not $sourceItem.PSIsContainer) { throw "Source is not a folder: $Source" }
$destination = Join-Path $DestinationRoot $sourceItem.Name
if ($null -ne (Get-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue)) {
    throw "Destination already exists: $destination"
}
New-Item -ItemType Junction -Path $destination -Target $sourceItem.FullName -ErrorAction Stop
```

When the script is executed rather than dot-sourced, use `-Source` when present; otherwise call `Get-ClipboardFolderPaths` and `Resolve-ClipboardSourcePath`. Print the resolved source and junction paths after success. Catch failures, write one actionable error, and return exit code 1.

- [x] **Step 4: Run the focused test suite and verify GREEN**

Run:

```powershell
Invoke-Pester .\create-junction.Tests.ps1
```

Expected: all tests pass with zero failures.

- [x] **Step 5: Commit the tested command**

```powershell
git add -- create-junction.ps1 create-junction.Tests.ps1
git commit -m "feat: add clipboard-based junction helper"
```

### Task 2: Usage documentation and end-to-end verification

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: `create-junction.ps1 [-Source <string>]` from Task 1
- Produces: documented clipboard and explicit-source workflows

- [x] **Step 1: Document both command forms**

Add a `create-junction.ps1` section to `README.md` containing:

````markdown
### Create a repository junction

Copy one folder in Windows File Explorer, change to the directory that should contain the link, then run:

```powershell
.\create-junction.ps1
```

Or provide the source explicitly:

```powershell
.\create-junction.ps1 -Source D:\GitHub\Payment
```

The command creates `<current-directory>\Payment` and never replaces an existing item.
````

- [x] **Step 2: Run automated verification**

Run:

```powershell
Invoke-Pester .\create-junction.Tests.ps1
```

Expected: all tests pass with zero failures.

- [x] **Step 3: Run explicit-source smoke test**

Create two temporary directories, execute the script from the destination directory with `-Source`, verify `LinkType` is `Junction`, then remove only the temporary test root.

- [x] **Step 4: Verify repository changes**

Run:

```powershell
git diff --check
git status --short
```

Expected: no whitespace errors; only the plan, script, test, and README changes from this feature plus the user's pre-existing untracked files are present.

- [x] **Step 5: Commit documentation**

```powershell
git add -- README.md docs/superpowers/plans/2026-07-13-create-junction.md
git commit -m "docs: explain junction helper usage"
```
