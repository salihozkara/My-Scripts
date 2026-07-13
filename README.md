# My Scripts

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
