# PowerShell script to analyze the organization of client folders

param(
    [string]$BasePath = "C:\Users\abhij\bb"
)

$Folders = @('BC', 'H1', 'IG', 'MS', 'SH')
$totalFolders = 0
$organizedFolders = 0
$problemFolders = @()

Write-Host "=== CHAOS DATABASE ORGANIZATION ANALYSIS ===" -ForegroundColor Yellow
Write-Host "Base Path: $BasePath" -ForegroundColor Gray
Write-Host ""

foreach ($folder in $Folders) {
    $folderPath = Join-Path $BasePath $folder
    Write-Host "Analyzing folder: $folder" -ForegroundColor Cyan
    
    if (!(Test-Path $folderPath)) {
        Write-Host "  ❌ Folder not found: $folderPath" -ForegroundColor Red
        continue
    }
    
    # Get all subdirectories (extracted folders)
    $extractedFolders = Get-ChildItem -Path $folderPath -Directory
    
    Write-Host "  Found $($extractedFolders.Count) client folders" -ForegroundColor White
    
    foreach ($extractedFolder in $extractedFolders) {
        $totalFolders++
        $rootsFile = Join-Path $extractedFolder.FullName "roots.txt"
        $assetsFile = Join-Path $extractedFolder.FullName "assets.txt"
        $tempFolder = Join-Path $extractedFolder.FullName "temp"
        
        $hasRoots = Test-Path $rootsFile
        $hasAssets = Test-Path $assetsFile
        $hasTemp = Test-Path $tempFolder
        
        if ($hasRoots -and $hasAssets -and $hasTemp) {
            $organizedFolders++
            
            # Check temp folder contents
            $tempContents = Get-ChildItem -Path $tempFolder -ErrorAction SilentlyContinue
            $tempFileCount = if ($tempContents) { $tempContents.Count } else { 0 }
            
            Write-Host "    ✅ $($extractedFolder.Name) - Complete (temp has $tempFileCount files)" -ForegroundColor Green
        } else {
            $missing = @()
            if (-not $hasRoots) { $missing += "roots.txt" }
            if (-not $hasAssets) { $missing += "assets.txt" }
            if (-not $hasTemp) { $missing += "temp folder" }
            
            Write-Host "    ❌ $($extractedFolder.Name) - Missing: $($missing -join ', ')" -ForegroundColor Red
            $problemFolders += "$folder/$($extractedFolder.Name)"
        }
    }
    Write-Host ""
}

# Summary
Write-Host "=== SUMMARY ===" -ForegroundColor Yellow
Write-Host "Total client folders: $totalFolders" -ForegroundColor White
Write-Host "Properly organized: $organizedFolders" -ForegroundColor Green
Write-Host "Problem folders: $($problemFolders.Count)" -ForegroundColor Red

if ($problemFolders.Count -gt 0) {
    Write-Host "`nProblematic folders:" -ForegroundColor Red
    foreach ($problemFolder in $problemFolders) {
        Write-Host "  - $problemFolder" -ForegroundColor Red
    }
}

$percentage = if ($totalFolders -gt 0) { [math]::Round(($organizedFolders / $totalFolders) * 100, 2) } else { 0 }
Write-Host "`nOrganization completion: $percentage%" -ForegroundColor $(if ($percentage -eq 100) { "Green" } else { "Yellow" })

Write-Host "`n=== ANALYSIS COMPLETE ===" -ForegroundColor Green
