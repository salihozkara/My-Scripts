$path = $args[0]

if([string]::IsNullOrEmpty($path))
{
    $path = "."
}

$fullPath = (Get-Item -Path $path).FullName

$envPath = [Environment]::GetEnvironmentVariable("PATH", "User")

$regexPattern = [regex]::Escape(";{0}" -f $fullPath)
$match = [regex]::Match($envPath, $regexPattern)

if($match.Success)
{
    $envPath = $envPath.Remove($match.Index, $match.Length)
    [Environment]::SetEnvironmentVariable("PATH", $envPath, "User")
    Write-Host "Path removed from PATH variable."
}
else
{
    Write-Host "Path does not exist in PATH variable."
}
