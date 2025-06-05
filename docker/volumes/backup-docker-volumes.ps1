$volumes = @(
    "docker_esdata01",
    "docker_huggingface",
    "docker_minio_data",
    "docker_mysql_data",
    "docker_redis_data"
)

$currentLocationPath = (Get-Location).Path
Write-Host "Script is running from (Windows path): $currentLocationPath"

# Convert Windows path to WSL-compatible path for volume mounting
$dockerHostPathForMount = $currentLocationPath
$driveLetterMatch = $currentLocationPath | Select-String -Pattern '^([A-Za-z]):'
if ($driveLetterMatch) {
    $drive = $driveLetterMatch.Matches[0].Groups[1].Value.ToLower()
    $pathWithoutDrive = $currentLocationPath.Substring(2)
    $dockerHostPathForMount = "/mnt/$drive$($pathWithoutDrive -replace '\\', '/')"
} else {
    Write-Warning "Path format '$currentLocationPath' not recognized for WSL conversion. Using it as is, which might cause issues."
}

Write-Host "Attempting to use WSL-compatible path for volume mount: $dockerHostPathForMount"

foreach ($volume in $volumes) {
    $tarFile = Join-Path $currentLocationPath "$volume.tar.gz"
    Write-Host "Backing up $volume to $tarFile ..."

    # Construct arguments for Docker using an array for clarity and safety
    $dockerArgs = @(
        "run", "--rm",
        "-v", "${volume}:/data", # Mount the named Docker volume
        "-v", "${dockerHostPathForMount}:/backup", # Use the WSL-compatible path
        "busybox", # The image to use
        "tar", "czvf", "/backup/${volume}.tar.gz", "-C", "/data", "." # Command to run in container
    )

    Write-Host "Executing: docker $($dockerArgs -join ' ')"
    & docker $dockerArgs # Execute docker with the arguments

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Backup of $volume completed successfully."
    } else {
        Write-Host "Backup of $volume failed! (Exit code: $LASTEXITCODE)" -ForegroundColor Red
    }
}
