$process = $args[0]

if($process -notlike "*.exe")
{
    $process = $process + ".exe"
}

taskkill.exe /IM $process /F