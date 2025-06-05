# List of your volume names
$volumes = @(
    "docker_esdata01",
    "docker_huggingface",
    "docker_minio_data",
    "docker_mysql_data",
    "docker_redis_data"
)

# Get current working directory for backup file location
$currentLocationPath = (Get-Location).Path
Write-Host "Script is running from (Windows path): $currentLocationPath"

# First, verify files exist on host
foreach ($volume in $volumes) {
    $tarFile = Join-Path $currentLocationPath "$volume.tar.gz"
    if (Test-Path $tarFile) {
        Write-Host "Confirmed file exists on host: $tarFile" -ForegroundColor Green
    } else {
        Write-Host "Warning: File does not exist on host: $tarFile" -ForegroundColor Yellow
    }
}

# Process each volume
foreach ($volume in $volumes) {
    $tarFile = Join-Path $currentLocationPath "$volume.tar.gz"
    if (Test-Path $tarFile) {
        Write-Host "Restoring $volume from $tarFile ..." -ForegroundColor Cyan

        # Create the volume if it doesn't exist
        Write-Host "Creating volume $volume (if not already present)..."
        docker volume create $volume | Out-Null

        # Create a temporary container with the volume attached
        # Using tail -f /dev/null to keep the container running
        $tempContainerName = "temp_restore_${volume}"
        Write-Host "Creating temporary container '$tempContainerName' with volume $volume..."
        docker run -d --name $tempContainerName -v "${volume}:/data" busybox tail -f /dev/null

        if ($LASTEXITCODE -eq 0) {
            # Copy the tar file directly into the container
            Write-Host "Copying $tarFile into container..."
            docker cp $tarFile "${tempContainerName}:/data/"

            if ($LASTEXITCODE -eq 0) {
                # Extract the archive inside the running container
                Write-Host "Extracting archive within the container..."
                $tarFileName = Split-Path $tarFile -Leaf
                $extractCommand = "cd /data && tar xzvf $tarFileName && rm $tarFileName"
                docker exec $tempContainerName sh -c $extractCommand

                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Restore of $volume completed successfully!" -ForegroundColor Green
                } else {
                    Write-Host "Failed to extract archive within container." -ForegroundColor Red
                }
            } else {
                Write-Host "Failed to copy archive into container." -ForegroundColor Red
            }

            # Clean up the temporary container
            Write-Host "Removing temporary container..."
            docker rm -f $tempContainerName > $null
        } else {
            Write-Host "Failed to create container." -ForegroundColor Red
        }
    } else {
        Write-Host "Backup file $tarFile not found! Skipping $volume." -ForegroundColor Yellow
    }
}

Write-Host "Volume restoration process completed." -ForegroundColor Green