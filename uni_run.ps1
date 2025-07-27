<#
.SYNOPSIS
    Universal Command Runner for Chaos Database - Execute commands across multiple client folders

.DESCRIPTION
    This script executes a given command in each client folder within the main directories (BC, H1, IG, MS, SH).
    It automatically discovers client folders that contain either 'assets.txt' or 'roots.txt' files and runs
    the specified command in each of them. Perfect for running reconnaissance tools like subfinder, httpx, 
    nuclei, etc. across your entire bug bounty target database.

.PARAMETER Command
    The command to execute in each client folder. This is a mandatory parameter.
    Examples: "subfinder -dL roots.txt -o subfinder.txt", "httpx -l assets.txt -o httpx.txt"

.PARAMETER BasePath
    The base directory containing the client folders. Defaults to "C:\Users\abhij\bb"

.PARAMETER Folders
    Array of main folder names to process. Defaults to @('BC', 'H1', 'IG', 'MS', 'SH')

.PARAMETER DryRun
    If specified, shows what commands would be executed without actually running them.
    Useful for testing and validation.

.PARAMETER ContinueOnError
    If specified, continues processing even if a command fails in one folder.
    Without this flag, the script stops on the first error.

.PARAMETER VerboseOutput
    Enables detailed logging including the exact command being executed in each folder
    and command output (when available).

.PARAMETER LogFile
    Path to a log file where all output will be written in addition to console output.
    If not specified, only console output is shown.

.EXAMPLE
    .\uni_run.ps1 "dir"
    Simple test - lists directory contents in each client folder

.EXAMPLE
    .\uni_run.ps1 "subfinder -dL roots.txt -o subfinder.txt" -ContinueOnError -VerboseOutput
    Runs subfinder on all root domains, continues on errors, with detailed logging

.EXAMPLE
    .\uni_run.ps1 "httpx -l assets.txt -o httpx_results.txt" -DryRun -VerboseOutput
    Dry run of httpx command to see what would be executed

.EXAMPLE
    .\uni_run.ps1 "nuclei -l assets.txt -o nuclei_scan.txt" -ContinueOnError -LogFile "nuclei_run.log"
    Runs nuclei scan with error continuation and logging to file

.EXAMPLE
    .\uni_run.ps1 "amass enum -df roots.txt -o amass_results.txt" -BasePath "D:\BugBounty" -Folders @('BC', 'H1')
    Runs amass with custom base path and only on BC and H1 folders

.NOTES
    Author: Created for Chaos Database Management
    Version: 2.0
    
    Prerequisites:
    - Client folders must contain either 'assets.txt' or 'roots.txt' files
    - The specified command/tool must be available in PATH or provide full path
    
    Features:
    - Automatic client folder discovery
    - Progress tracking with percentage completion
    - Colored console output for better readability
    - Comprehensive error handling and reporting
    - Dry run capability for testing
    - Optional logging to file
    - Execution statistics and success rate calculation
    
    Exit Codes:
    - 0: All commands executed successfully
    - 1: One or more commands failed or prerequisites not met

.LINK
    For updates and issues: https://github.com/your-repo/chaos-db-tools
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Command,
    
    [string]$BasePath = "C:\Users\abhij\bb",
    
    [string[]]$Folders = @('BC', 'H1', 'IG', 'MS', 'SH'),
    
    [switch]$DryRun,
    
    [switch]$ContinueOnError,
    
    [switch]$VerboseOutput,
    
    [string]$LogFile = "",
    
    [switch]$Help
)

# Function to write log messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Color coding for console output
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "INFO" { "White" }
        default { "Gray" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
    
    # Write to log file if specified
    if ($LogFile -ne "") {
        Add-Content -Path $LogFile -Value $logMessage
    }
}

# Function to validate prerequisites
function Test-Prerequisites {
    Write-Log "Validating prerequisites..." "INFO"
    
    # Check if base path exists
    if (!(Test-Path $BasePath)) {
        Write-Log "Base path does not exist: $BasePath" "ERROR"
        return $false
    }
    
    # Check if any folders exist
    $foundFolders = 0
    foreach ($folder in $Folders) {
        $folderPath = Join-Path $BasePath $folder
        if (Test-Path $folderPath) {
            $foundFolders++
        }
    }
    
    if ($foundFolders -eq 0) {
        Write-Log "No valid folders found in: $BasePath" "ERROR"
        return $false
    }
    
    Write-Log "Found $foundFolders valid folders" "SUCCESS"
    return $true
}

# Function to count total client folders
function Get-TotalClientFolders {
    $total = 0
    foreach ($folder in $Folders) {
        $folderPath = Join-Path $BasePath $folder
        if (Test-Path $folderPath) {
            $clientFolders = Get-ChildItem -Path $folderPath -Directory
            $total += $clientFolders.Count
        }
    }
    return $total
}

# Function to execute command in a folder
function Invoke-CommandInFolder {
    param(
        [string]$FolderPath,
        [string]$FolderName,
        [string]$Command
    )
    
    try {
        # Change to the target directory
        Push-Location $FolderPath
        
        if ($VerboseOutput) {
            Write-Log "Executing in ${FolderName}: $Command" "INFO"
        }
        
        if ($DryRun) {
            Write-Log "DRY RUN - Would execute: $Command" "WARN"
            return $true
        }
        
        # Execute the command
        $result = Invoke-Expression $Command 2>&1
        
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
            Write-Log "✅ SUCCESS: $FolderName" "SUCCESS"
            if ($VerboseOutput -and $result) {
                Write-Log "Output: $result" "INFO"
            }
            return $true
        } else {
            Write-Log "❌ FAILED: $FolderName (Exit code: $LASTEXITCODE)" "ERROR"
            if ($result) {
                Write-Log "Error output: $result" "ERROR"
            }
            return $false
        }
        
    } catch {
        Write-Log "❌ EXCEPTION in ${FolderName}: $($_.Exception.Message)" "ERROR"
        return $false
    } finally {
        # Always return to original directory
        Pop-Location
    }
}

# Main execution
function Main {
    Write-Log "=== UNIVERSAL COMMAND RUNNER ===" "INFO"
    Write-Log "Base Path: $BasePath" "INFO"
    Write-Log "Command: $Command" "INFO"
    Write-Log "Folders: $($Folders -join ', ')" "INFO"
    
    if ($DryRun) {
        Write-Log "DRY RUN MODE - No commands will be executed" "WARN"
    }
    
    if ($LogFile -ne "") {
        Write-Log "Logging to file: $LogFile" "INFO"
    }
    
    Write-Log "" "INFO"
    
    # Validate prerequisites
    if (!(Test-Prerequisites)) {
        Write-Log "Prerequisites validation failed. Exiting." "ERROR"
        exit 1
    }
    
    # Get total count for progress tracking
    $totalFolders = Get-TotalClientFolders
    Write-Log "Total client folders to process: $totalFolders" "INFO"
    Write-Log "" "INFO"
    
    # Execution statistics
    $processed = 0
    $successful = 0
    $failed = 0
    $skipped = 0
    
    # Process each main folder
    foreach ($folder in $Folders) {
        $folderPath = Join-Path $BasePath $folder
        
        if (!(Test-Path $folderPath)) {
            Write-Log "Skipping non-existent folder: $folder" "WARN"
            continue
        }
        
        Write-Log "Processing folder: $folder" "INFO"
        
        # Get all client subdirectories
        $clientFolders = Get-ChildItem -Path $folderPath -Directory
        
        if ($clientFolders.Count -eq 0) {
            Write-Log "No client folders found in: $folder" "WARN"
            continue
        }
        
        # Process each client folder
        foreach ($clientFolder in $clientFolders) {
            $processed++
            $progressPercent = [math]::Round(($processed / $totalFolders) * 100, 1)
            
            # Check if folder has the required structure
            $hasAssets = Test-Path (Join-Path $clientFolder.FullName "assets.txt")
            $hasRoots = Test-Path (Join-Path $clientFolder.FullName "roots.txt")
            
            if (!$hasAssets -and !$hasRoots) {
                Write-Log "⚠️ SKIP: $($folder)/$($clientFolder.Name) - Missing assets.txt and roots.txt" "WARN"
                $skipped++
                continue
            }
            
            Write-Log "[$processed/$totalFolders] ($progressPercent%) Processing: $($folder)/$($clientFolder.Name)" "INFO"
            
            # Execute command in the client folder
            $success = Invoke-CommandInFolder -FolderPath $clientFolder.FullName -FolderName "$($folder)/$($clientFolder.Name)" -Command $Command
            
            if ($success) {
                $successful++
            } else {
                $failed++
                
                # Check if we should continue on error
                if (!$ContinueOnError) {
                    Write-Log "Stopping execution due to error. Use -ContinueOnError to continue despite failures." "ERROR"
                    break
                }
            }
        }
        
        # Break outer loop if we're not continuing on error
        if ($failed -gt 0 -and !$ContinueOnError) {
            break
        }
        
        Write-Log "" "INFO"
    }
    
    # Final summary
    Write-Log "=== EXECUTION SUMMARY ===" "INFO"
    Write-Log "Total folders: $totalFolders" "INFO"
    Write-Log "Processed: $processed" "INFO"
    Write-Log "Successful: $successful" "SUCCESS"
    Write-Log "Failed: $failed" $(if ($failed -gt 0) { "ERROR" } else { "INFO" })
    Write-Log "Skipped: $skipped" "WARN"
    
    $successRate = if ($processed -gt 0) { [math]::Round(($successful / $processed) * 100, 1) } else { 0 }
    Write-Log "Success rate: $successRate%" $(if ($successRate -eq 100) { "SUCCESS" } else { "WARN" })
    
    Write-Log "=== EXECUTION COMPLETE ===" "INFO"
    
    # Exit with appropriate code
    if ($failed -gt 0) {
        exit 1
    } else {
        exit 0
    }
}

# Show help if requested
if ($Help) {
    Get-Help $MyInvocation.MyCommand.Definition -Detailed
    exit 0
}

# Parameter validation
if ([string]::IsNullOrWhiteSpace($Command)) {
    Write-Host "ERROR: Command parameter is required!" -ForegroundColor Red
    Write-Host ""
    Write-Host "USAGE EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  .\uni_run.ps1 `"dir`"" -ForegroundColor Green
    Write-Host "  .\uni_run.ps1 `"subfinder -dL roots.txt -o subfinder.txt`" -ContinueOnError -VerboseOutput" -ForegroundColor Green
    Write-Host "  .\uni_run.ps1 `"httpx -l assets.txt -o httpx.txt`" -DryRun" -ForegroundColor Green
    Write-Host ""
    Write-Host "For detailed help: .\uni_run.ps1 -Help" -ForegroundColor Cyan
    exit 1
}

# Start execution
Main
