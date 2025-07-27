# Process Chaos DB ZIP files and extract root domains
# This script will:
# 1. Unzip each file in BC, H1, IG, MS, SH folders
# 2. Move the zip file into the extracted folder
# 3. Find CSV files and extract root domains
# 4. Create roots.txt file with unique root domains

param(
    [string]$BasePath = "C:\Users\abhij\bb"
)

$Folders = @('BC', 'H1', 'IG', 'MS', 'SH')

function Extract-RootDomain {
    param([string]$Domain)
    
    if ([string]::IsNullOrWhiteSpace($Domain)) {
        return $null
    }
    
    # Clean the domain
    $Domain = $Domain.Trim().ToLower()
    
    # Remove wildcards and underscores from the beginning
    $Domain = $Domain -replace '^[*._]+', ''
    
    # Remove protocol if present
    $Domain = $Domain -replace '^https?://', ''
    
    # Remove www. prefix
    $Domain = $Domain -replace '^www\.', ''
    
    # Remove path, query, fragment
    $Domain = ($Domain -split '[/?#]')[0]
    
    # Remove port if present
    $Domain = ($Domain -split ':')[0]
    
    # Skip if empty after cleanup
    if ([string]::IsNullOrWhiteSpace($Domain)) {
        return $null
    }
    
    # Skip if it's an IP address
    if ($Domain -match '^\d+\.\d+\.\d+\.\d+$') {
        return $null
    }
    
    # Skip if domain doesn't contain at least one dot
    if ($Domain -notmatch '\.') {
        return $null
    }
    
    # Extract root domain (handle subdomains)
    $parts = $Domain -split '\.'
    if ($parts.Length -ge 2) {
        # For domains like example.com, subdomain.example.com
        # We want to extract the root domain (example.com)
        
        # Handle common TLDs
        $commonTlds = @('co.uk', 'com.au', 'co.jp', 'co.in', 'com.br', 'co.za')
        
        foreach ($tld in $commonTlds) {
            if ($Domain.EndsWith(".$tld")) {
                $withoutTld = $Domain.Substring(0, $Domain.Length - $tld.Length - 1)
                $remainingParts = $withoutTld -split '\.'
                if ($remainingParts.Length -gt 0) {
                    return "$($remainingParts[-1]).$tld"
                }
            }
        }
        
        # Standard case: take last two parts
        if ($parts.Length -ge 2) {
            return "$($parts[-2]).$($parts[-1])"
        }
    }
    
    return $Domain
}

function Process-CsvFile {
    param(
        [string]$CsvPath,
        [string]$OutputPath
    )
    
    Write-Host "  Processing CSV: $CsvPath" -ForegroundColor Cyan
    
    $rootDomains = New-Object System.Collections.Generic.HashSet[string]
    
    try {
        # Try to read CSV with different encodings
        $content = $null
        try {
            $content = Import-Csv -Path $CsvPath -Delimiter ',' -Encoding UTF8
        } catch {
            try {
                $content = Import-Csv -Path $CsvPath -Delimiter ';' -Encoding UTF8
            } catch {
                try {
                    $content = Get-Content $CsvPath -Encoding UTF8 | ConvertFrom-Csv -Delimiter ','
                } catch {
                    $content = Get-Content $CsvPath -Encoding UTF8 | ConvertFrom-Csv -Delimiter ';'
                }
            }
        }
        
        if ($content) {
            foreach ($row in $content) {
                # Try different column names that might contain domains
                $possibleColumns = @('domain', 'scope', 'asset', 'target', 'url', 'host', 'hostname', 'subdomain')
                
                foreach ($prop in $row.PSObject.Properties) {
                    $columnName = $prop.Name.ToLower()
                    $value = $prop.Value
                    
                    # Check if this column likely contains domain information
                    if ($possibleColumns -contains $columnName -or 
                        $columnName -match 'domain|scope|asset|target|url|host') {
                        
                        if (![string]::IsNullOrWhiteSpace($value)) {
                            # Handle multiple domains in one field (comma or space separated)
                            $domains = $value -split '[,\s]+' | Where-Object { $_ -and $_.Trim() }
                            
                            foreach ($domain in $domains) {
                                $rootDomain = Extract-RootDomain -Domain $domain.Trim()
                                if ($rootDomain -and $rootDomain.Length -gt 0) {
                                    [void]$rootDomains.Add($rootDomain)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        # If no domains found, try reading as plain text and extract domain-like patterns
        if ($rootDomains.Count -eq 0) {
            Write-Host "    No domains found in CSV columns, trying pattern matching..." -ForegroundColor Yellow
            $rawContent = Get-Content $CsvPath -Raw -Encoding UTF8
            
            # Look for domain patterns
            $domainPattern = '(?:[a-zA-Z0-9](?:[a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}'
            $matches = [regex]::Matches($rawContent, $domainPattern)
            
            foreach ($match in $matches) {
                $rootDomain = Extract-RootDomain -Domain $match.Value
                if ($rootDomain -and $rootDomain.Length -gt 0) {
                    [void]$rootDomains.Add($rootDomain)
                }
            }
        }
        
    } catch {
        Write-Host "    Error processing CSV: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Trying alternative parsing..." -ForegroundColor Yellow
        
        # Last resort: read as plain text and extract domain patterns
        try {
            $rawContent = Get-Content $CsvPath -Raw -Encoding UTF8
            $domainPattern = '(?:[a-zA-Z0-9](?:[a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}'
            $matches = [regex]::Matches($rawContent, $domainPattern)
            
            foreach ($match in $matches) {
                $rootDomain = Extract-RootDomain -Domain $match.Value
                if ($rootDomain -and $rootDomain.Length -gt 0) {
                    [void]$rootDomains.Add($rootDomain)
                }
            }
        } catch {
            Write-Host "    Failed to extract domains from CSV" -ForegroundColor Red
        }
    }
    
    if ($rootDomains.Count -gt 0) {
        $sortedDomains = $rootDomains | Sort-Object
        $sortedDomains | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "    Found $($rootDomains.Count) unique root domains" -ForegroundColor Green
    } else {
        Write-Host "    No domains found in this CSV" -ForegroundColor Yellow
    }
}

# Main processing loop
foreach ($folder in $Folders) {
    $folderPath = Join-Path $BasePath $folder
    Write-Host "`n=== Processing folder: $folder ===" -ForegroundColor Yellow
    
    if (!(Test-Path $folderPath)) {
        Write-Host "Folder $folderPath not found, skipping..." -ForegroundColor Red
        continue
    }
    
    $zipFiles = Get-ChildItem -Path $folderPath -Filter "*.zip"
    
    foreach ($zipFile in $zipFiles) {
        $zipName = [System.IO.Path]::GetFileNameWithoutExtension($zipFile.Name)
        $extractPath = Join-Path $folderPath $zipName
        
        Write-Host "`nProcessing: $($zipFile.Name)" -ForegroundColor Cyan
        
        # Create extraction directory
        if (!(Test-Path $extractPath)) {
            New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
        }
        
        try {
            # Extract ZIP file
            Write-Host "  Extracting to: $extractPath" -ForegroundColor Gray
            Expand-Archive -Path $zipFile.FullName -DestinationPath $extractPath -Force
            
            # Move ZIP file into extracted folder
            $zipDestination = Join-Path $extractPath $zipFile.Name
            Move-Item -Path $zipFile.FullName -Destination $zipDestination -Force
            Write-Host "  Moved ZIP file to: $zipDestination" -ForegroundColor Gray
            
            # Find TXT files in the extracted folder
            $txtFiles = Get-ChildItem -Path $extractPath -Filter "*.txt" -Recurse
            
            if ($txtFiles.Count -gt 0) {
                Write-Host "  Found $($txtFiles.Count) TXT file(s)" -ForegroundColor Green
                
# Create roots.txt and assets.txt files
                $rootsFile = Join-Path $extractPath "roots.txt"
                $assetsFile = Join-Path $extractPath "assets.txt"

                # Collect file names (without .txt) and all content
                $fileNames = New-Object System.Collections.Generic.HashSet[string]
                $allContent = New-Object System.Collections.ArrayList
                
                foreach ($txtFile in $txtFiles) {
                    Write-Host "    Processing: $($txtFile.Name)" -ForegroundColor Gray

                    # Add file name without .txt to roots
                    $fileNameWithoutTxt = [System.IO.Path]::GetFileNameWithoutExtension($txtFile.Name)
                    [void]$fileNames.Add($fileNameWithoutTxt)

                    # Add content to assets
                    $lines = Get-Content -Path $txtFile.FullName -Encoding UTF8
                    if ($lines -is [array]) {
                        [void]$allContent.AddRange($lines)
                    } elseif ($lines) {
                        [void]$allContent.Add($lines)
                    }
                }

                # Write final roots.txt
                if ($fileNames.Count -gt 0) {
                    $sortedNames = $fileNames | Sort-Object
                    $sortedNames | Out-File -FilePath $rootsFile -Encoding UTF8
                    Write-Host "  Created roots.txt with $($fileNames.Count) unique domain roots" -ForegroundColor Green
                } else {
                    "# No domain roots found in TXT files" | Out-File -FilePath $rootsFile -Encoding UTF8
                    Write-Host "  Created empty roots.txt (no domain roots found)" -ForegroundColor Yellow
                }

                # Write final assets.txt
                if ($allContent.Count -gt 0) {
                    $uniqueContent = $allContent | Sort-Object -Unique
                    $uniqueContent | Out-File -FilePath $assetsFile -Encoding UTF8
                    Write-Host "  Created assets.txt with all unique TXT file contents" -ForegroundColor Green
                } else {
                    "# No content found in TXT files" | Out-File -FilePath $assetsFile -Encoding UTF8
                    Write-Host "  Created empty assets.txt (no content found)" -ForegroundColor Yellow
                }
                
            } else {
                Write-Host "  No TXT files found in extracted folder" -ForegroundColor Yellow
                # Create empty roots.txt
                $rootsFile = Join-Path $extractPath "roots.txt"
                "# No TXT files found" | Out-File -FilePath $rootsFile -Encoding UTF8
            }
            
        } catch {
            Write-Host "  Error processing $($zipFile.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n=== Processing Complete ===" -ForegroundColor Green
Write-Host "All ZIP files have been processed. Each extracted folder now contains:" -ForegroundColor White
Write-Host "  - The original ZIP file" -ForegroundColor White
Write-Host "  - Extracted contents" -ForegroundColor White
Write-Host "  - roots.txt file with domain names (from TXT file names)" -ForegroundColor White
Write-Host "  - assets.txt file with all unique content from TXT files" -ForegroundColor White
