# Chaos Database Scripts - Quick Reference

## 🚀 Universal Command Runner (PowerShell)

### Basic Commands
```powershell
# Show help
.\uni_run.ps1 -Help

# Simple test
.\uni_run.ps1 "dir"

# Dry run (preview)
.\uni_run.ps1 "echo test" -DryRun -VerboseOutput
```

### Common Bug Bounty Commands
```powershell
# Subdomain enumeration
.\uni_run.ps1 "subfinder -dL roots.txt -o subfinder.txt" -ContinueOnError -VerboseOutput

# Live host discovery
.\uni_run.ps1 "httpx -l assets.txt -o live_hosts.txt" -ContinueOnError

# Vulnerability scanning
.\uni_run.ps1 "nuclei -l assets.txt -o nuclei_results.txt" -ContinueOnError -LogFile "nuclei.log"

# Port scanning
.\uni_run.ps1 "nmap -iL assets.txt -oN nmap_scan.txt" -ContinueOnError

# Directory bruteforcing
.\uni_run.ps1 "gobuster dir -u \$(cat assets.txt) -w wordlist.txt" -ContinueOnError
```

### Advanced Usage
```powershell
# Custom path and folders
.\uni_run.ps1 "command" -BasePath "D:\BugBounty" -Folders @('BC', 'H1')

# With logging and error handling
.\uni_run.ps1 "command" -ContinueOnError -LogFile "run.log" -VerboseOutput

# Dry run on specific folders
.\uni_run.ps1 "command" -DryRun -Folders @('BC') -VerboseOutput
```

## 🗂️ Folder Organization (PowerShell)

### Basic Commands
```powershell
# Show help
.\organize_folders.ps1 -Help

# Preview what will be organized
.\organize_folders.ps1 -DryRun -VerboseOutput

# Actually organize folders
.\organize_folders.ps1 -VerboseOutput

# Organize specific folders only
.\organize_folders.ps1 -Folders @('BC', 'H1') -VerboseOutput
```

## 🐧 Universal Command Runner (Bash)

### Basic Commands
```bash
# Show help
./uni_run.sh -h

# Simple test
./uni_run.sh "ls -la"

# Dry run with verbose
./uni_run.sh -d -v "echo test"
```

### Common Commands
```bash
# Subdomain enumeration
./uni_run.sh -c -v "subfinder -dL roots.txt -o subfinder.txt"

# Live host discovery
./uni_run.sh -c "httpx -l assets.txt -o live_hosts.txt"

# With logging
./uni_run.sh -l scan.log -c "nuclei -l assets.txt"
```

## 📊 Key Features Summary

| Feature | PowerShell | Bash |
|---------|------------|------|
| Help System | `-Help` | `-h` |
| Dry Run | `-DryRun` | `-d` |
| Verbose Output | `-VerboseOutput` | `-v` |
| Continue on Error | `-ContinueOnError` | `-c` |
| Log to File | `-LogFile "file"` | `-l file` |
| Custom Path | `-BasePath "path"` | `-p path` |
| Custom Folders | `-Folders @('BC','H1')` | Built-in |

## 🎯 Common Workflows

### 1. Initial Setup & Organization
```powershell
# Preview organization
.\organize_folders.ps1 -DryRun -VerboseOutput

# Organize folders
.\organize_folders.ps1 -VerboseOutput
```

### 2. Subdomain Discovery Workflow
```powershell
# Step 1: Subdomain enumeration
.\uni_run.ps1 "subfinder -dL roots.txt -o subfinder.txt" -ContinueOnError -LogFile "subdomain_enum.log"

# Step 2: Probe for live hosts
.\uni_run.ps1 "httpx -l subfinder.txt -o live_hosts.txt" -ContinueOnError

# Step 3: Update assets file
.\uni_run.ps1 "cat live_hosts.txt >> assets.txt" -ContinueOnError
```

### 3. Vulnerability Assessment Workflow
```powershell
# Step 1: Port scanning
.\uni_run.ps1 "nmap -iL assets.txt -oN nmap_results.txt" -ContinueOnError -LogFile "nmap.log"

# Step 2: Vulnerability scanning
.\uni_run.ps1 "nuclei -l assets.txt -o nuclei_results.txt" -ContinueOnError -LogFile "nuclei.log"

# Step 3: Directory bruteforcing
.\uni_run.ps1 "gobuster dir -u \$(cat assets.txt) -w common.txt" -ContinueOnError
```

## 🔧 Pro Tips

1. **Always dry run first**: Use `-DryRun` to preview commands before execution
2. **Use continue-on-error**: Add `-ContinueOnError` for batch operations
3. **Enable logging**: Use `-LogFile` for audit trails
4. **Verbose output**: Add `-VerboseOutput` for troubleshooting
5. **Custom folders**: Limit scope with `-Folders` parameter
6. **Screen/tmux**: Use for long-running commands

## 📈 Statistics Tracking

Both scripts provide:
- **Total folders processed**
- **Success/failure counts**  
- **Progress percentage**
- **Success rate calculation**
- **Execution time tracking**

## 🚨 Safety Reminders

- ✅ Test with `-DryRun` first
- ✅ Use `-ContinueOnError` for batch jobs
- ✅ Keep logs with `-LogFile`
- ✅ Monitor progress with verbose output
- ❌ Never run untested commands on all targets
- ❌ Don't forget rate limiting for external tools

## 📞 Getting Help

```powershell
# Detailed help
.\uni_run.ps1 -Help
.\organize_folders.ps1 -Help

# Examples only
Get-Help .\uni_run.ps1 -Examples

# Full documentation
Get-Help .\uni_run.ps1 -Full
```

```bash
# Bash help
./uni_run.sh -h
```

---
*For full documentation, see `README.md`*
