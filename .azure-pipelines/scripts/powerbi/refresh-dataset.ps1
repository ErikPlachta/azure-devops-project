# Refresh Power BI Dataset
# Triggers a dataset refresh and optionally waits for completion
#
# Required parameters:
#   -WorkspaceId      Target workspace GUID
#   -DatasetId        Dataset to refresh
#
# Optional parameters:
#   -Wait             Wait for refresh to complete (default: true)
#   -TimeoutMinutes   Max wait time (default: 30)
#   -NotifyOption     NoNotification (default) | MailOnFailure | MailOnCompletion

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspaceId,

    [Parameter(Mandatory=$true)]
    [string]$DatasetId,

    [bool]$Wait = $true,

    [int]$TimeoutMinutes = 30,

    [ValidateSet('NoNotification', 'MailOnFailure', 'MailOnCompletion')]
    [string]$NotifyOption = 'NoNotification'
)

$ErrorActionPreference = "Stop"

Import-Module MicrosoftPowerBIMgmt -ErrorAction Stop

Write-Host "##[section]Power BI Dataset Refresh"
Write-Host "  Workspace: $WorkspaceId"
Write-Host "  Dataset: $DatasetId"
Write-Host "  Wait: $Wait"
Write-Host "  Timeout: $TimeoutMinutes minutes"

# Get access token
$accessToken = (Get-PowerBIAccessToken -AsString).Replace("Bearer ", "")
$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

# Get dataset info
$dsInfoUri = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/datasets/$DatasetId"
try {
    $dsInfo = Invoke-RestMethod -Uri $dsInfoUri -Method Get -Headers $headers
    Write-Host "  Dataset Name: $($dsInfo.name)"
    Write-Host "  Configured By: $($dsInfo.configuredBy)"
} catch {
    Write-Error "Failed to get dataset info: $_"
    exit 1
}

# Check if refresh is already in progress
$historyUri = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/datasets/$DatasetId/refreshes?`$top=1"
$lastRefresh = Invoke-RestMethod -Uri $historyUri -Method Get -Headers $headers

if ($lastRefresh.value.Count -gt 0 -and $lastRefresh.value[0].status -eq "Unknown") {
    Write-Host "##[section]Refresh already in progress"
    $refreshId = $lastRefresh.value[0].requestId
} else {
    # Trigger refresh
    Write-Host "##[section]Triggering refresh..."

    $refreshUri = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/datasets/$DatasetId/refreshes"
    $body = @{
        notifyOption = $NotifyOption
    } | ConvertTo-Json

    try {
        $response = Invoke-WebRequest -Uri $refreshUri -Method Post -Headers $headers -Body $body
        Write-Host "  ✓ Refresh triggered"

        # Get refresh ID from response header or query
        $refreshHistory = Invoke-RestMethod -Uri $historyUri -Method Get -Headers $headers
        $refreshId = $refreshHistory.value[0].requestId
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__

        if ($statusCode -eq 400) {
            Write-Warning "Cannot refresh: Dataset may not support refresh or refresh already in progress"
            exit 0
        }
        throw $_
    }
}

Write-Host "  Refresh ID: $refreshId"

# Wait for completion if requested
if ($Wait) {
    Write-Host "##[section]Waiting for refresh to complete..."

    $startTime = Get-Date
    $timeout = $startTime.AddMinutes($TimeoutMinutes)
    $pollInterval = 10  # seconds

    while ((Get-Date) -lt $timeout) {
        Start-Sleep -Seconds $pollInterval

        $statusUri = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/datasets/$DatasetId/refreshes?`$top=1"
        $status = Invoke-RestMethod -Uri $statusUri -Method Get -Headers $headers

        $currentRefresh = $status.value | Where-Object { $_.requestId -eq $refreshId }

        if (-not $currentRefresh) {
            $currentRefresh = $status.value[0]
        }

        $refreshStatus = $currentRefresh.status
        $elapsed = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)

        Write-Host "  Status: $refreshStatus (elapsed: $elapsed min)"

        switch ($refreshStatus) {
            'Completed' {
                Write-Host ""
                Write-Host "##[section]✓ Refresh completed successfully"
                Write-Host "  Duration: $elapsed minutes"
                Write-Host "  End Time: $($currentRefresh.endTime)"
                exit 0
            }
            'Failed' {
                Write-Host ""
                Write-Host "##vso[task.logissue type=error]Refresh failed"

                # Get error details
                if ($currentRefresh.serviceExceptionJson) {
                    $errorDetails = $currentRefresh.serviceExceptionJson | ConvertFrom-Json
                    Write-Host "  Error: $($errorDetails.errorDescription)"
                }

                exit 1
            }
            'Cancelled' {
                Write-Warning "Refresh was cancelled"
                exit 1
            }
            'Disabled' {
                Write-Warning "Refresh is disabled for this dataset"
                exit 0
            }
        }
    }

    # Timeout
    Write-Warning "Refresh timed out after $TimeoutMinutes minutes"
    Write-Host "Refresh may still be running in Power BI Service"
    exit 1
} else {
    Write-Host "##[section]Refresh triggered (not waiting for completion)"
    Write-Host "##vso[task.setvariable variable=RefreshId;isOutput=true]$refreshId"
}
