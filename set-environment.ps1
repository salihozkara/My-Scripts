$path = $args[0]

if([string]::IsNullOrEmpty($path))
{
    $path = "."
}

$fullPath = (Get-Item -Path $path).FullName

$envPath = [Environment]::GetEnvironmentVariable("PATH", "User")

if($envPath -notlike "*$fullPath*")
{
    $envPath = $envPath + ";$fullPath"
    [Environment]::SetEnvironmentVariable("PATH", $envPath, "User")

    Write-Host "Path added to PATH variable."
}else {
    Write-Host "Path already exists"
}