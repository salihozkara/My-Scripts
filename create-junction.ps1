[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Source
)

function Resolve-ClipboardSourcePath {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()]
        [object[]]$ClipboardItems
    )

    $items = @($ClipboardItems)

    if ($items.Count -ne 1) {
        throw "Clipboard must contain exactly one copied folder; found $($items.Count)."
    }

    $path = [string]$items[0]

    if ([string]::IsNullOrWhiteSpace($path)) {
        throw "The copied clipboard item does not contain a folder path."
    }

    return $path
}

function Get-ClipboardFolderPaths {
    [CmdletBinding()]
    param()

    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        throw "Clipboard folder discovery is supported only on Windows."
    }

    $runspace = $null
    $powerShell = $null

    try {
        $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
        $runspace.ApartmentState = [System.Threading.ApartmentState]::STA
        $runspace.ThreadOptions = [System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread
        $runspace.Open()

        $powerShell = [System.Management.Automation.PowerShell]::Create()
        $powerShell.Runspace = $runspace

        [void]$powerShell.AddScript(@'
Add-Type -AssemblyName System.Windows.Forms

$fileDropList = [System.Windows.Forms.Clipboard]::GetFileDropList()
foreach ($path in $fileDropList) {
    [string]$path
}
'@)

        $result = $powerShell.Invoke()

        if ($powerShell.HadErrors) {
            $details = ($powerShell.Streams.Error | ForEach-Object { $_.Exception.Message }) -join "; "
            throw "Could not read copied folders from the Windows clipboard. $details"
        }

        return @($result | ForEach-Object { [string]$_ })
    }
    finally {
        if ($null -ne $powerShell) {
            $powerShell.Dispose()
        }

        if ($null -ne $runspace) {
            $runspace.Dispose()
        }
    }
}

function New-RepositoryJunction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [string]$DestinationRoot = (Get-Location).ProviderPath
    )

    if ([string]::IsNullOrWhiteSpace($Source)) {
        throw "Source folder path cannot be empty."
    }

    $sourceItem = Get-Item -LiteralPath $Source -Force -ErrorAction SilentlyContinue

    if ($null -eq $sourceItem) {
        throw "Source folder was not found: $Source"
    }

    if (-not $sourceItem.PSIsContainer) {
        throw "Source is not a folder: $($sourceItem.FullName)"
    }

    if ($null -eq $sourceItem.Parent -or [string]::IsNullOrWhiteSpace($sourceItem.Name)) {
        throw "Source must have a folder name and cannot be a filesystem root: $($sourceItem.FullName)"
    }

    $destinationRootItem = Get-Item -LiteralPath $DestinationRoot -Force -ErrorAction SilentlyContinue

    if ($null -eq $destinationRootItem -or -not $destinationRootItem.PSIsContainer) {
        throw "Destination root is not an existing folder: $DestinationRoot"
    }

    $destination = Join-Path $destinationRootItem.FullName $sourceItem.Name
    $existingItem = Get-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue

    if ($null -ne $existingItem) {
        throw "Destination already exists and was not changed: $destination"
    }

    return New-Item -ItemType Junction -Path $destination -Target $sourceItem.FullName -ErrorAction Stop
}

if ($MyInvocation.InvocationName -ne ".") {
    try {
        if ($PSBoundParameters.ContainsKey("Source")) {
            $selectedSource = $Source
        }
        else {
            $clipboardItems = @(Get-ClipboardFolderPaths)
            $selectedSource = Resolve-ClipboardSourcePath -ClipboardItems $clipboardItems
        }

        $junction = New-RepositoryJunction -Source $selectedSource

        Write-Host "Junction created."
        Write-Host "Source:   $($junction.Target)"
        Write-Host "Junction: $($junction.FullName)"
    }
    catch {
        Write-Error $_.Exception.Message
        exit 1
    }
}
