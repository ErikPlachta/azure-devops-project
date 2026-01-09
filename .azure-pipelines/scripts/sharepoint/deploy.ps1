# Deploy files to SharePoint document library
# Uses PnP.PowerShell for authentication and upload
#
# Required parameters:
#   -SiteUrl         SharePoint site URL
#   -TargetFolder    Document library folder path
#   -SourceFolder    Local folder to upload
#
# Optional parameters:
#   -FilePatterns    File patterns to include (default: "*")
#   -ExcludePatterns Patterns to exclude
#   -CleanTarget     Remove existing files first
#   -DryRun          Preview without uploading

param(
    [Parameter(Mandatory=$true)]
    [string]$SiteUrl,

    [Parameter(Mandatory=$true)]
    [string]$TargetFolder,

    [Parameter(Mandatory=$true)]
    [string]$SourceFolder,

    [string]$FilePatterns = "*",
    [string]$ExcludePatterns = "",
    [switch]$CleanTarget,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "##[section]SharePoint Deployment"
Write-Host "  Site: $SiteUrl"
Write-Host "  Target: $TargetFolder"
Write-Host "  Source: $SourceFolder"
Write-Host "  Patterns: $FilePatterns"
if ($DryRun) { Write-Host "  Mode: DRY RUN" }

# Install PnP.PowerShell if needed
if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
    Write-Host "Installing PnP.PowerShell..."
    Install-Module -Name PnP.PowerShell -Force -AllowClobber -Scope CurrentUser
}

Import-Module PnP.PowerShell

# Connect using managed identity or cached credentials
Write-Host "##[section]Connecting to SharePoint..."
try {
    Connect-PnPOnline -Url $SiteUrl -ManagedIdentity
    Write-Host "Connected via Managed Identity"
} catch {
    Write-Host "Managed Identity not available, trying interactive..."
    Connect-PnPOnline -Url $SiteUrl -Interactive
}

# Clean target if requested
if ($CleanTarget -and -not $DryRun) {
    Write-Host "##[section]Cleaning target folder..."
    try {
        $existingFiles = Get-PnPFolderItem -FolderSiteRelativeUrl $TargetFolder -ItemType File
        foreach ($file in $existingFiles) {
            Write-Host "  Removing: $($file.Name)"
            Remove-PnPFile -ServerRelativeUrl $file.ServerRelativeUrl -Force
        }
    } catch {
        Write-Host "##vso[task.logissue type=warning]Could not clean folder: $_"
    }
}

# Get files to upload
Write-Host "##[section]Finding files to upload..."
$patterns = $FilePatterns -split ','
$excludes = if ($ExcludePatterns) { $ExcludePatterns -split ',' } else { @() }

$files = @()
foreach ($pattern in $patterns) {
    $pattern = $pattern.Trim()
    $found = Get-ChildItem -Path $SourceFolder -Filter $pattern -Recurse -File
    $files += $found
}

# Apply exclusions
if ($excludes.Count -gt 0) {
    $files = $files | Where-Object {
        $name = $_.Name
        $exclude = $false
        foreach ($ex in $excludes) {
            if ($name -like "*$($ex.Trim())*") {
                $exclude = $true
                break
            }
        }
        -not $exclude
    }
}

$files = $files | Select-Object -Unique
Write-Host "Found $($files.Count) files to upload"

# Upload files
$uploaded = 0
$failed = 0

foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($SourceFolder.Length).TrimStart('\', '/')
    $targetPath = "$TargetFolder/$relativePath" -replace '\\', '/'
    $targetDir = Split-Path $targetPath -Parent

    Write-Host "  $relativePath -> $targetPath"

    if ($DryRun) {
        Write-Host "    [DRY RUN] Would upload"
        continue
    }

    try {
        # Ensure target directory exists
        $folderPath = $targetDir -replace '^/', ''
        try {
            Resolve-PnPFolder -SiteRelativePath $folderPath | Out-Null
        } catch {
            # Folder doesn't exist, create it
            $parts = $folderPath -split '/'
            $current = ""
            foreach ($part in $parts) {
                if ($part) {
                    $current = if ($current) { "$current/$part" } else { $part }
                    try {
                        Add-PnPFolder -Name $part -Folder ($current -replace "/$part$", "") -ErrorAction SilentlyContinue | Out-Null
                    } catch { }
                }
            }
        }

        # Upload file
        Add-PnPFile -Path $file.FullName -Folder $folderPath | Out-Null
        $uploaded++
    } catch {
        Write-Host "##vso[task.logissue type=warning]Failed to upload $relativePath : $_"
        $failed++
    }
}

# Disconnect
Disconnect-PnPOnline

Write-Host ""
Write-Host "##[section]Deployment Summary"
Write-Host "  Total files: $($files.Count)"
if ($DryRun) {
    Write-Host "  Mode: DRY RUN (no files uploaded)"
} else {
    Write-Host "  Uploaded: $uploaded"
    Write-Host "  Failed: $failed"
}

if ($failed -gt 0) {
    Write-Host "##vso[task.logissue type=warning]$failed files failed to upload"
}
