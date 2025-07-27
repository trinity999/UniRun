# Chaos Database Management Scripts

A collection of PowerShell and Bash scripts for managing bug bounty target databases across multiple platforms (BugCrowd, HackerOne, Intigriti, etc.).

## 📁 Scripts Overview

### 1. `uni_run.ps1` - Universal Command Runner (PowerShell)
**Purpose**: Execute reconnaissance commands across all client folders in your database.

**Features**:
- Automatic client folder discovery
- Progress tracking with percentage completion
- Colored console output
- Dry run capability
- Error handling with continue-on-error option
- Detailed logging with optional file output
- Execution statistics and success rate calculation

**Usage**:
```powershell
# Show help
.\uni_run.ps1 -Help

# Basic usage
.\uni_run.ps1 "dir"

# Run subfinder on all root domains
.\uni_run.ps1 "subfinder -dL roots.txt -o subfinder.txt" -ContinueOnError -VerboseOutput

# Dry run to test command
.\uni_run.ps1 "httpx -l assets.txt -o httpx.txt" -DryRun -VerboseOutput

# With custom base path and specific folders
.\uni_run.ps1 "nuclei -l assets.txt" -BasePath "D:\BugBounty" -Folders @('BC', 'H1')

# With logging to file
.\uni_run.ps1 "amass enum -df roots.txt" -LogFile "amass_run.log" -ContinueOnError
```

**Parameters**:
- `-Command` (Required): Command to execute in each folder
- `-BasePath`: Base directory (default: `C:\Users\abhij\bb`)
- `-Folders`: Array of folders to process (default: BC, H1, IG, MS, SH)
- `-DryRun`: Show what would be executed without running
- `-ContinueOnError`: Continue even if commands fail
- `-VerboseOutput`: Enable detailed logging
- `-LogFile`: Path to log file for output
- `-Help`: Show detailed help

---

### 2. `uni_run.sh` - Universal Command Runner (Bash)
**Purpose**: Linux/Unix version of the universal command runner.

**Features**:
- Same functionality as PowerShell version
- POSIX-compliant shell scripting
- Colored terminal output
- Progress tracking and statistics

**Usage**:
```bash
# Show help
./uni_run.sh -h

# Basic usage
./uni_run.sh "ls -la"

# Run with verbose output and continue on error
./uni_run.sh -v -c "subfinder -dL roots.txt -o subfinder.txt"

# Dry run
./uni_run.sh --dry-run "httpx -l assets.txt -o httpx.txt"

# With custom path and logging
./uni_run.sh -p /custom/path -l scan.log "nuclei -l assets.txt"
```

**Options**:
- `-d, --dry-run`: Show what would be executed
- `-c, --continue-on-error`: Continue on failures
- `-v, --verbose`: Enable detailed output
- `-l, --log-file FILE`: Write to log file
- `-p, --path PATH`: Custom base path
- `-h, --help`: Show help message

---

### 3. `organize_folders.ps1` - Folder Organization Script
**Purpose**: Clean up client folders by moving files into organized temp subdirectories.

**Features**:
- Creates `temp` folders in each client directory
- Moves all files except `roots.txt` and `assets.txt` to temp
- Preserves important domain files for easy access
- Dry run capability for testing
- Verbose logging with statistics

**Usage**:
```powershell
# Show help
.\organize_folders.ps1 -Help

# Basic organization
.\organize_folders.ps1

# Dry run to see what would be moved
.\organize_folders.ps1 -DryRun -VerboseOutput

# Custom path and specific folders
.\organize_folders.ps1 -BasePath "D:\BugBounty" -Folders @('BC', 'H1')

# Verbose mode for detailed logging
.\organize_folders.ps1 -VerboseOutput
```

**What it does**:
- **Keeps in main folder**: `roots.txt`, `assets.txt`
- **Moves to temp folder**: All reconnaissance outputs, scan results, temporary files

**Parameters**:
- `-BasePath`: Base directory (default: `C:\Users\abhij\bb`)
- `-Folders`: Array of folders to process
- `-DryRun`: Preview mode without making changes
- `-VerboseOutput`: Detailed logging
- `-Help`: Show help information

---

## 🚀 Quick Start Guide

### Prerequisites
1. **PowerShell 5.0+** (Windows) or **Bash 4.0+** (Linux/Unix)
2. **Tools in PATH**: Ensure reconnaissance tools (subfinder, httpx, nuclei, etc.) are accessible
3. **Folder Structure**: Client folders must contain `assets.txt` or `roots.txt`

### Initial Setup
1. Clone or download scripts to your chaos database directory
2. Ensure scripts have execution permissions:
   ```bash
   chmod +x uni_run.sh
   ```

### Typical Workflow
1. **Organize folders** (if needed):
   ```powershell
   .\organize_folders.ps1 -DryRun  # Preview first
   .\organize_folders.ps1          # Actually organize
   ```

2. **Run reconnaissance commands**:
   ```powershell
   # Subdomain enumeration
   .\uni_run.ps1 "subfinder -dL roots.txt -o subfinder.txt" -ContinueOnError

   # Asset probing
   .\uni_run.ps1 "httpx -l assets.txt -o live_hosts.txt" -ContinueOnError

   # Vulnerability scanning
   .\uni_run.ps1 "nuclei -l assets.txt -o nuclei_results.txt" -ContinueOnError
   ```

## 📊 Output and Logging

All scripts provide:
- **Colored console output** for better readability
- **Progress tracking** with percentage completion
- **Error handling** with detailed error messages
- **Statistics** showing success/failure rates
- **Optional file logging** for audit trails

## 🔧 Customization

### Adding New Platforms
To add support for new bug bounty platforms, modify the `$Folders` array:
```powershell
$Folders = @('BC', 'H1', 'IG', 'MS', 'SH', 'YesWeHack', 'Bugbase')
```

### Custom Commands
The scripts work with any command-line tool:
```powershell
# Custom nmap scanning
.\uni_run.ps1 "nmap -iL assets.txt -oN nmap_scan.txt"

# Custom directory bruteforcing
.\uni_run.ps1 "gobuster dir -u \$(cat assets.txt) -w wordlist.txt"
```

## 🛡️ Safety Features

- **Dry Run Mode**: Test commands before execution
- **Error Handling**: Graceful failure handling
- **File Preservation**: Important files (`roots.txt`, `assets.txt`) are never moved/deleted
- **Logging**: Full audit trail of all operations
- **Progress Tracking**: Monitor long-running operations

## 📋 Exit Codes

- **0**: Success - All operations completed successfully
- **1**: Partial failure - Some commands failed but execution continued
- **2**: Critical failure - Prerequisites not met or invalid usage

## 🤝 Contributing

To extend these scripts:
1. Follow existing code patterns
2. Add comprehensive error handling
3. Include help documentation
4. Test with dry run modes
5. Maintain cross-platform compatibility where possible

## 📝 Version History

- **v2.0**: Added comprehensive documentation, help systems, and improved error handling
- **v1.5**: Added bash version and organization script
- **v1.0**: Initial PowerShell universal runner

---

**Author**: Created for Chaos Database Management  
**License**: Use responsibly for authorized security testing only  
**Support**: For issues and updates, check the repository
