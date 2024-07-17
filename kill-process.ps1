($isContainingName, $process) = find-process.ps1 $args[0]

if ($null -eq $process) {
    return
}

if ($true -eq $isContainingName) {
    for($i = 0; $i -lt $process.Count; $i++) {
        Write-Host $i": $($process[$i].ProcessName) with id $($process[$i].Id)"
    }
    Write-Host "Processes found. Which ones do you want to kill? (separate by space, a for all, q to quit)"
    $answer = Read-Host

    if ($answer -eq "q") {
        return
    }

    if ($answer -ne "a") {
        $process = $answer.Split(" ") | ForEach-Object { $process[$_] }   
    }
}


foreach ($p in $process) {
    Write-Host "Killing $($p.ProcessName) with id $($p.Id)..."
}

$process | Stop-Process -Force