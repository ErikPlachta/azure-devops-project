# Deploy Power BI Reports (PBIX and RDL)
# Imports reports to a Power BI workspace via REST API
#
# Required parameters:
#   -WorkspaceId      Target workspace GUID
#   -ReportPath       Path to report file or folder (supports wildcards)
#
# Optional parameters:
#   -ConflictAction   CreateOrOverwrite (default) | Abort | Ignore
#   -ReportType       auto (default) | pbix | rdl
#   -NameOverride     Custom display name for report

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspaceId,

    [Parameter(Mandatory=$true)]
    [string]$ReportPath,

    [ValidateSet('CreateOrOverwrite', 'Abort', 'Ignore')]
    [string]$ConflictAction = 'CreateOrOverwrite',

    [ValidateSet('auto', 'pbix', 'rdl')]
    [string]$ReportType = 'auto',

    [string]$NameOverride = ''
)

$ErrorActionPreference = "Stop"

# Ensure Power BI module is available
if (-not (Get-Module -ListAvailable -Name MicrosoftPowerBIMgmt)) {
    Write-Host "Installing MicrosoftPowerBIMgmt module..."
    Install-Module -Name MicrosoftPowerBIMgmt -Force -Scope CurrentUser -AllowClobber
}

Import-Module MicrosoftPowerBIMgmt

Write-Host "##[section]Power BI Report Deployment"
Write-Host "  Workspace: $WorkspaceId"
Write-Host "  Path: $ReportPath"
Write-Host "  Conflict: $ConflictAction"

# Check if already connected (Service Principal should be connected via AzureCLI task)
try {
    $context = Get-PowerBIAccessToken -ErrorAction Stop
    Write-Host "Using existing Power BI connection"
} catch {
    Write-Error "Not connected to Power BI. Ensure you're authenticated via Service Principal."
    Write-Host "Run: Connect-PowerBIServiceAccount -ServicePrincipal -Credential (Get-Credential) -TenantId <tenant>"
    exit 1
}

# Find report files
$files = @()
if (Test-Path $ReportPath -PathType Leaf) {
    $files += Get-Item $ReportPath
} else {
    $files += Get-ChildItem -Path $ReportPath -Include "*.pbix","*.rdl" -Recurse -File
}

if ($files.Count -eq 0) {
    Write-Warning "No report files found at: $ReportPath"
    exit 0
}

Write-Host "##[section]Found $($files.Count) report(s) to deploy"

$deployed = @()
$failed = @()

foreach ($file in $files) {
    $fileName = $file.Name
    $extension = $file.Extension.ToLower()

    # Determine report type
    $type = $ReportType
    if ($type -eq 'auto') {
        $type = switch ($extension) {
            '.pbix' { 'pbix' }
            '.rdl'  { 'rdl' }
            default {
                Write-Warning "Unknown file type: $fileName - skipping"
                continue
            }
        }
    }

    # Report name (without extension)
    $reportName = if ($NameOverride) { $NameOverride } else { [System.IO.Path]::GetFileNameWithoutExtension($fileName) }

    Write-Host ""
    Write-Host "##[section]Deploying: $fileName"
    Write-Host "  Type: $type"
    Write-Host "  Name: $reportName"

    try {
        # Import based on type
        $importResult = $null

        if ($type -eq 'pbix') {
            # PBIX import
            $importResult = New-PowerBIReport -Path $file.FullName -WorkspaceId $WorkspaceId -Name $reportName -ConflictAction $ConflictAction
        }
        elseif ($type -eq 'rdl') {
            # RDL import via REST API (New-PowerBIReport doesn't support RDL)
            $accessToken = (Get-PowerBIAccessToken -AsString).Replace("Bearer ", "")

            $boundary = [System.Guid]::NewGuid().ToString()
            $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
            $fileEnc = [System.Text.Encoding]::GetEncoding('iso-8859-1').GetString($fileBytes)

            $bodyLines = @(
                "--$boundary",
                "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"",
                "Content-Type: application/octet-stream",
                "",
                $fileEnc,
                "--$boundary--"
            )
            $body = $bodyLines -join "`r`n"

            $uri = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/imports?datasetDisplayName=$reportName&nameConflict=$ConflictAction"

            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type"  = "multipart/form-data; boundary=$boundary"
            }

            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            $importResult = $response

            # Poll for import completion
            if ($response.id) {
                $importId = $response.id
                $maxAttempts = 30
                $attempt = 0

                do {
                    Start-Sleep -Seconds 2
                    $attempt++
                    $statusUri = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/imports/$importId"
                    $statusResponse = Invoke-RestMethod -Uri $statusUri -Method Get -Headers @{ "Authorization" = "Bearer $accessToken" }
                    $importStatus = $statusResponse.importState
                    Write-Host "  Import status: $importStatus (attempt $attempt/$maxAttempts)"
                } while ($importStatus -eq "Publishing" -and $attempt -lt $maxAttempts)

                if ($importStatus -ne "Succeeded") {
                    throw "Import failed with status: $importStatus"
                }

                $importResult = $statusResponse
            }
        }

        Write-Host "  ✓ Deployed successfully"

        # Extract report/dataset IDs
        $reportId = $null
        $datasetId = $null

        if ($importResult.reports) {
            $reportId = $importResult.reports[0].id
        } elseif ($importResult.Id) {
            $reportId = $importResult.Id
        }

        if ($importResult.datasets) {
            $datasetId = $importResult.datasets[0].id
        }

        $deployed += @{
            Name = $reportName
            Type = $type
            ReportId = $reportId
            DatasetId = $datasetId
            File = $fileName
        }

        # Output for pipeline variables
        if ($reportId) {
            Write-Host "##vso[task.setvariable variable=DeployedReportId;isOutput=true]$reportId"
        }
        if ($datasetId) {
            Write-Host "##vso[task.setvariable variable=DeployedDatasetId;isOutput=true]$datasetId"
        }
    }
    catch {
        Write-Host "##vso[task.logissue type=error]Failed to deploy $fileName : $_"
        $failed += @{
            Name = $reportName
            File = $fileName
            Error = $_.Exception.Message
        }
    }
}

# Summary
Write-Host ""
Write-Host "##[section]Deployment Summary"
Write-Host "  Deployed: $($deployed.Count)"
Write-Host "  Failed: $($failed.Count)"

if ($deployed.Count -gt 0) {
    Write-Host ""
    Write-Host "Deployed reports:"
    foreach ($r in $deployed) {
        Write-Host "  - $($r.Name) ($($r.Type)) → ReportId: $($r.ReportId)"
    }
}

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "##vso[task.logissue type=warning]Failed reports:"
    foreach ($f in $failed) {
        Write-Host "  - $($f.Name): $($f.Error)"
    }
    exit 1
}

# Output deployed reports as JSON for downstream tasks
$deployedJson = $deployed | ConvertTo-Json -Compress
Write-Host "##vso[task.setvariable variable=DeployedReports;isOutput=true]$deployedJson"
