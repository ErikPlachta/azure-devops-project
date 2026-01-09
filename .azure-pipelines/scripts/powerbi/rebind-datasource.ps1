# Rebind Power BI Data Sources
# Updates connection strings for deployed reports/datasets per environment
#
# Required parameters:
#   -WorkspaceId      Target workspace GUID
#   -DatasetId        Dataset to rebind (or use -ReportId)
#   -ConfigFile       JSON config file with environment settings
#   -Environment      Target environment key in config
#
# Optional parameters:
#   -ReportId         Report ID (will lookup associated dataset)
#   -TakeOver         Take ownership of dataset (required for RDL)

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspaceId,

    [string]$DatasetId = '',

    [string]$ReportId = '',

    [Parameter(Mandatory=$true)]
    [string]$ConfigFile,

    [Parameter(Mandatory=$true)]
    [string]$Environment,

    [switch]$TakeOver
)

$ErrorActionPreference = "Stop"

Import-Module MicrosoftPowerBIMgmt -ErrorAction Stop

Write-Host "##[section]Power BI Data Source Rebinding"
Write-Host "  Workspace: $WorkspaceId"
Write-Host "  Environment: $Environment"
Write-Host "  Config: $ConfigFile"

# Load config
if (-not (Test-Path $ConfigFile)) {
    Write-Error "Config file not found: $ConfigFile"
    exit 1
}

$config = Get-Content $ConfigFile | ConvertFrom-Json
$envConfig = $config.$Environment

if (-not $envConfig) {
    Write-Error "Environment '$Environment' not found in config file"
    Write-Host "Available environments: $($config.PSObject.Properties.Name -join ', ')"
    exit 1
}

Write-Host "  Server: $($envConfig.server)"
Write-Host "  Database: $($envConfig.database)"

# Get access token
$accessToken = (Get-PowerBIAccessToken -AsString).Replace("Bearer ", "")
$headers = @{ "Authorization" = "Bearer $accessToken" }

# Resolve DatasetId from ReportId if needed
if (-not $DatasetId -and $ReportId) {
    Write-Host "##[section]Looking up dataset for report: $ReportId"

    $reportUri = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/reports/$ReportId"
    $report = Invoke-RestMethod -Uri $reportUri -Method Get -Headers $headers

    if ($report.datasetId) {
        $DatasetId = $report.datasetId
        Write-Host "  Found dataset: $DatasetId"
    } else {
        Write-Warning "Report has no associated dataset - may be RDL without embedded data"
    }
}

if (-not $DatasetId) {
    Write-Error "No DatasetId provided or found"
    exit 1
}

# Take ownership if requested (required for RDL/paginated reports)
if ($TakeOver) {
    Write-Host "##[section]Taking ownership of dataset..."
    try {
        $takeOverUri = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/datasets/$DatasetId/Default.TakeOver"
        Invoke-RestMethod -Uri $takeOverUri -Method Post -Headers $headers
        Write-Host "  ✓ Ownership taken"
    } catch {
        Write-Warning "TakeOver failed (may already own): $_"
    }
}

# Get current datasources
Write-Host "##[section]Getting current data sources..."
$dsUri = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/datasets/$DatasetId/datasources"
$datasources = Invoke-RestMethod -Uri $dsUri -Method Get -Headers $headers

if ($datasources.value.Count -eq 0) {
    Write-Warning "No data sources found for dataset"
    exit 0
}

Write-Host "  Found $($datasources.value.Count) data source(s)"

foreach ($ds in $datasources.value) {
    Write-Host "  - Type: $($ds.datasourceType), Server: $($ds.connectionDetails.server), Database: $($ds.connectionDetails.database)"
}

# Build update request
$updateRequests = @()

foreach ($ds in $datasources.value) {
    # Only update SQL-type datasources
    if ($ds.datasourceType -in @('Sql', 'AnalysisServices', 'AzureSqlDatabase')) {
        $updateRequests += @{
            datasourceSelector = @{
                datasourceType = $ds.datasourceType
                connectionDetails = @{
                    server = $ds.connectionDetails.server
                    database = $ds.connectionDetails.database
                }
            }
            connectionDetails = @{
                server = $envConfig.server
                database = $envConfig.database
            }
        }
    }
}

if ($updateRequests.Count -eq 0) {
    Write-Host "No SQL-type data sources to update"
    exit 0
}

# Update datasources
Write-Host "##[section]Updating data sources..."
$updateUri = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/datasets/$DatasetId/Default.UpdateDatasources"
$body = @{ updateDetails = $updateRequests } | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri $updateUri -Method Post -Headers $headers -Body $body -ContentType "application/json"
    Write-Host "  ✓ Data sources updated"
} catch {
    Write-Error "Failed to update data sources: $_"
    exit 1
}

# Set credentials if provided in config
if ($envConfig.credentialType) {
    Write-Host "##[section]Setting data source credentials..."

    # Get gateway datasources
    $gwDsUri = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/datasets/$DatasetId/Default.GetBoundGatewayDatasources"
    try {
        $gwDatasources = Invoke-RestMethod -Uri $gwDsUri -Method Get -Headers $headers

        foreach ($gwDs in $gwDatasources.value) {
            $credBody = $null

            switch ($envConfig.credentialType) {
                'OAuth2' {
                    # OAuth requires interactive flow - skip in CI
                    Write-Host "  OAuth2 credentials must be set manually"
                }
                'Basic' {
                    if ($envConfig.username -and $envConfig.password) {
                        $credBody = @{
                            credentialDetails = @{
                                credentialType = "Basic"
                                credentials = "{`"credentialData`":[{`"name`":`"username`",`"value`":`"$($envConfig.username)`"},{`"name`":`"password`",`"value`":`"$($envConfig.password)`"}]}"
                                encryptedConnection = "Encrypted"
                                encryptionAlgorithm = "None"
                                privacyLevel = "Organizational"
                            }
                        }
                    }
                }
                'Key' {
                    if ($envConfig.key) {
                        $credBody = @{
                            credentialDetails = @{
                                credentialType = "Key"
                                credentials = "{`"credentialData`":[{`"name`":`"key`",`"value`":`"$($envConfig.key)`"}]}"
                                encryptedConnection = "Encrypted"
                                encryptionAlgorithm = "None"
                                privacyLevel = "Organizational"
                            }
                        }
                    }
                }
            }

            if ($credBody) {
                $credUri = "https://api.powerbi.com/v1.0/myorg/gateways/$($gwDs.gatewayId)/datasources/$($gwDs.id)"
                try {
                    Invoke-RestMethod -Uri $credUri -Method Patch -Headers $headers -Body ($credBody | ConvertTo-Json -Depth 10) -ContentType "application/json"
                    Write-Host "  ✓ Credentials set for gateway datasource"
                } catch {
                    Write-Warning "Failed to set credentials: $_"
                }
            }
        }
    } catch {
        Write-Host "  No gateway datasources (using cloud connection)"
    }
}

# Verify update
Write-Host "##[section]Verifying update..."
$verifyDs = Invoke-RestMethod -Uri $dsUri -Method Get -Headers $headers

foreach ($ds in $verifyDs.value) {
    Write-Host "  - Server: $($ds.connectionDetails.server), Database: $($ds.connectionDetails.database)"
}

Write-Host ""
Write-Host "##[section]Data source rebinding complete"
