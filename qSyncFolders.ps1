param (
    [string]$SourceFolder,
    [string]$ReplicaFolder,
    [string]$LogFile
)

function Log-Message {
    param (
        [string]$Message
    )
    $Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $LogEntry = "$Timestamp - $Message"
    Add-Content -Path $LogFile -Value $LogEntry
    Write-Output $LogEntry
}

# Ensure log file exists
if (-not (Test-Path $LogFile)) {
    New-Item -Path $LogFile -ItemType File -Force
}

# Function to synchronize folders
function Sync-Folders {
    param (
        [string]$Source,
        [string]$Destination
    )

    # Get lists of files and directories
    $sourceItems = Get-ChildItem -Path $Source -Recurse
    $destinationItems = Get-ChildItem -Path $Destination -Recurse

    # Synchronize files and folders
    foreach ($sourceItem in $sourceItems) {
        $relativePath = $sourceItem.FullName.Substring($Source.Length)
        $destinationPath = Join-Path -Path $Destination -ChildPath $relativePath

        if ($sourceItem.PSIsContainer) {
            if (-not (Test-Path $destinationPath)) {
                New-Item -Path $destinationPath -ItemType Directory
                Log-Message "Created directory: $destinationPath"
            }
        } else {
            if (-not (Test-Path $destinationPath) -or (Get-Item -Path $destinationPath).LastWriteTime -lt $sourceItem.LastWriteTime) {
                Copy-Item -Path $sourceItem.FullName -Destination $destinationPath -Force
                Log-Message "Copied file: $sourceItem.FullName to $destinationPath"
            }
        }
    }

    # Remove items in the destination that are not in the source
    foreach ($destinationItem in $destinationItems) {
        $relativePath = $destinationItem.FullName.Substring($Destination.Length)
        $sourcePath = Join-Path -Path $Source -ChildPath $relativePath

        if (-not (Test-Path $sourcePath)) {
            if ($destinationItem.PSIsContainer) {
                Remove-Item -Path $destinationItem.FullName -Recurse -Force
                Log-Message "Removed directory: $destinationItem.FullName"
            } else {
                Remove-Item -Path $destinationItem.FullName -Force
                Log-Message "Removed file: $destinationItem.FullName"
            }
        }
    }
}

# Execute synchronization
Sync-Folders -Source $SourceFolder -Destination $ReplicaFolder
