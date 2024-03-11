$port = $args[0]

if([string]::IsNullOrEmpty($port))
{
    Write-Host "Please provide a port number."
    return
}

$process = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue

if($null -eq $process)
{
    Write-Host "Process not found."
    return
}

Write-Host "Found $($process.Count) processes:"

# process infos and State, CreationTime, OwningProcess, ProcessName, Id
$process | ForEach-Object { Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue }