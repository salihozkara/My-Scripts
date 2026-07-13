# Create Junction Script Design

## Purpose

Add a PowerShell helper that links a repository folder into the current working directory without copying it. The common workflow is to copy a folder in Windows File Explorer, open a terminal in the consuming repository, and run the script.

## Interface

The script is named `create-junction.ps1` and supports two invocation forms:

```powershell
.\create-junction.ps1
.\create-junction.ps1 -Source D:\GitHub\Payment
```

When `-Source` is supplied, the script uses it and does not inspect the clipboard. Without `-Source`, the script reads the Windows clipboard and requires exactly one copied folder.

## Behavior

The script resolves the source to an absolute directory path. It creates a directory junction in the caller's current working directory and gives the junction the source directory's leaf name. For example, a source of `D:\GitHub\Payment` and a current directory of `D:\GitHub\Host\modules` produces `D:\GitHub\Host\modules\Payment` pointing to the source.

The script prints both paths after successful creation.

## Validation and Safety

- The source must exist and must be a directory.
- Clipboard mode accepts exactly one filesystem item, and that item must be a directory.
- The source directory must have a usable leaf name.
- If a file, directory, junction, or symbolic link already exists at the destination, the script stops without changing or deleting it.
- Errors explain how the caller can correct the input.

## Components and Data Flow

The script separates source discovery from junction creation:

1. Resolve the explicit `-Source` argument, or obtain one copied path from the clipboard.
2. Validate and normalize the source directory.
3. Derive the destination from the process current working directory and source leaf name.
4. Confirm that the destination does not exist.
5. Create the junction and report the result.

## Testing

Automated PowerShell tests use temporary directories to cover explicit-source resolution, destination-name derivation, successful junction creation, and rejection of missing sources or occupied destinations. Clipboard interpretation is kept behind a small boundary so its validation can be tested with supplied clipboard-like values without depending on a user's live clipboard.

Manual verification covers the Windows File Explorer workflow: copy one folder, change to a different directory, run the script without arguments, and confirm that the resulting junction resolves to the copied folder.
