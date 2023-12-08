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

    if($process.Count -gt 0)
    {
        Write-Host "Found $($process.Count) processes:"
        foreach($p in $process)
        {
            Write-Host "    $($p.ProcessName) with id $($p.Id)"
        }

        Write-Host "Processes found. Do you want to kill all of them? (y/n)"
        $answer = Read-Host

        if($answer -ne "n")
        {
            Write-Host "Killing all processes..."
        }
        else
        {
            Write-Host "Aborting..."
            return
        }
    }
}

if($null -eq $process)
{
    Write-Host "Process not found."
    return
}


foreach($p in $process)
{
    Write-Host "Killing $($p.ProcessName) with id $($p.Id)..."
}

$process | Stop-Process -Force