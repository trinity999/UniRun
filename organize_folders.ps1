<#
.SYNOPSIS
    Folder Organization Script for Chaos Database - Organize client folders by moving files into temp subdirectories

.DESCRIPTION
    This script organizes client folders within bug bounty database directories by creating a 'temp' 
    subfolder in each client directory and moving all files (except important domain summary files) 
    into it. This keeps the client folders clean while maintaining easy access to critical files.

.PARAMETER BasePath
    The base directory containing the client folders. Defaults to "C:\Users\abhij\bb"

.PARAMETER Folders
    Array of main folder names to process. Defaults to @('BC', 'H1', 'IG', 'MS', 'SH')

.PARAMETER DryRun
    If specified, shows what operations would be performed without actually executing them.
    Useful for testing and validation before running the actual organization.

.PARAMETER VerboseOutput
    Enables detailed logging showing each file operation and folder being processed.

.PARAMETER Help
    Shows detailed help information about the script.

.EXAMPLE
    .\organize_folders.ps1
    Basic usage - organizes all client folders in default directories

.EXAMPLE
    .\organize_folders.ps1 -DryRun -VerboseOutput
    Dry run with verbose output to see what would be done

.EXAMPLE
    .\organize_folders.ps1 -BasePath "D:\BugBounty" -Folders @('BC', 'H1')
    Organize only BC and H1 folders in a custom base path

.EXAMPLE
    .\organize_folders.ps1 -VerboseOutput
    Run organization with detailed logging of all operations

.NOTES
    Author: Created for Chaos Database Management
    Version: 1.5
    
    What this script does:
    - Creates a 'temp' folder in each client directory (if it doesn't exist)
    - Moves all files EXCEPT 'roots.txt' and 'assets.txt' into the temp folder
    - Preserves the important domain summary files for easy access
    - Processes all client folders within the specified main directories
    
    Files that are kept in the main client folder:
    - roots.txt (root domains for the target)
    - assets.txt (discovered assets/subdomains)
    
    Files that are moved to temp folder:
    - All reconnaissance tool outputs
    - Scan results
    - Temporary files
    - Any other files not specified as important
    
    Prerequisites:
    - PowerShell 5.0 or higher
    - Write access to the target directories
    
    Exit Codes:
    - 0: Organization completed successfully
    - 1: Error occurred during processing

.LINK
    For updates and issues: https://github.com/your-repo/chaos-db-tools
#>

[CmdletBinding()]
param(
    [string]$BasePath = "C:\Users\abhij\bb",
    [string[]]$Folders = @('BC', 'H1', 'IG', 'MS', 'SH'),
    [switch]$DryRun,
    [switch]$VerboseOutput,
    [switch]$Help
)

# Show help if requested
if ($Help) {
    Get-Help $MyInvocation.MyCommand.Definition -Detailed
    exit 0
}

# Function to write log messages with colors
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    if ($VerboseOutput) {
        $logMessage = "[$timestamp] [$Level] $Message"
    } else {
        $logMessage = $Message
    }
    
    # Color coding for console output
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "INFO" { "White" }
        default { "Gray" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

Write-Log "=== FOLDER ORGANIZATION SCRIPT ===" "INFO"
Write-Log "Base Path: $BasePath" "INFO"
Write-Log "Folders: $($Folders -join ', ')" "INFO"

if ($DryRun) {
    Write-Log "DRY RUN MODE - No files will be moved" "WARN"
}

Write-Log "" "INFO"

# Statistics
$totalProcessed = 0
$totalMoved = 0
$totalErrors = 0

foreach ($folder in $Folders) {
    $folderPath = Join-Path $BasePath $folder
    Write-Log "Organizing folder: $folder" "INFO"
    
    if (!(Test-Path $folderPath)) {
        Write-Log "Folder $folderPath not found, skipping..." "ERROR"
        continue
    }
    
    # Get all subdirectories (client folders)
    $clientFolders = Get-ChildItem -Path $folderPath -Directory
    
    foreach ($clientFolder in $clientFolders) {
        $totalProcessed++
        $tempFolder = Join-Path $clientFolder.FullName "temp"
        
        if ($VerboseOutput) {
            Write-Log "Processing client folder: $($clientFolder.Name)" "INFO"
        }

        # Create a temp folder if it doesn't exist
        if (!(Test-Path $tempFolder)) {
            if ($DryRun) {
                Write-Log "DRY RUN - Would create temp folder in $($clientFolder.Name)" "WARN"
            } else {
                try {
                    New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null
                    Write-Log "Created temp folder in $($clientFolder.Name)" "SUCCESS"
                } catch {
                    Write-Log "Error creating temp folder in $($clientFolder.Name): $($_.Exception.Message)" "ERROR"
                    $totalErrors++
                    continue
                }
            }
        }

        # Find files to move (all except roots.txt, assets.txt, and temp folder)
        $filesToMove = Get-ChildItem -Path $clientFolder.FullName | Where-Object { 
            $_.Name -ne "roots.txt" -and 
            $_.Name -ne "assets.txt" -and 
            $_.Name -ne "temp" 
        }

        if ($filesToMove.Count -gt 0) {
            foreach ($file in $filesToMove) {
                if ($DryRun) {
                    Write-Log "DRY RUN - Would move $($file.Name) to temp" "WARN"
                } else {
                    try {
                        Move-Item -Path $file.FullName -Destination $tempFolder -Force -ErrorAction Stop
                        Write-Log "Moved $($file.Name) to temp" "SUCCESS"
                        $totalMoved++
                    } catch {
                        Write-Log "Error moving $($file.Name): $($_.Exception.Message)" "ERROR"
                        $totalErrors++
                    }
                }
            }
        } else {
            if ($VerboseOutput) {
                Write-Log "No files to move in $($clientFolder.Name)" "INFO"
            }
        }
    }
}

# Final summary
Write-Log "" "INFO"
Write-Log "=== ORGANIZATION SUMMARY ===" "INFO"
Write-Log "Client folders processed: $totalProcessed" "INFO"
if (!$DryRun) {
    Write-Log "Files moved: $totalMoved" "SUCCESS"
    Write-Log "Errors: $totalErrors" $(if ($totalErrors -gt 0) { "ERROR" } else { "INFO" })
} else {
    Write-Log "DRY RUN - No actual changes made" "WARN"
}
Write-Log "=== ORGANIZATION COMPLETE ===" "SUCCESS"

