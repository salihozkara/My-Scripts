$idOrName = $args[0]

if([string]::IsNullOrEmpty($idOrName))
{
    Write-Host "Please provide a process id or name."
    return
}

$process = Get-Process -Name $idOrName -ErrorAction SilentlyContinue

if($idOrName -is [int] -and $null -eq $process)
{
    Write-Host "Process name not found. Trying to find process by id..."
    $process = Get-Process -Id $idOrName -ErrorAction SilentlyContinue
}

if($null -eq $process)
{
    Write-Host "Process not found. Trying to find process by containing name..."
    $process = Get-Process -Name "*$idOrName*" -ErrorAction SilentlyContinue

    if($null -eq $process)
    {
        Write-Host "Process not found."
        return
    }

    Write-Host "Found $($process.Count) processes:"
    return $process, $true
}

if($null -eq $process)
{
    Write-Host "Process not found."
    return
}

Write-Host "Found $($process.Count) processes:"

return $process