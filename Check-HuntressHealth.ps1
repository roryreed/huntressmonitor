<#
.SYNOPSIS
    Checks the health status of the Huntress EDR agent.

.DESCRIPTION
    This script queries the Huntress agent's local health API endpoint to determine
    if the agent is running and healthy. It returns the overall status (Healthy, 
    Degraded, or Unhealthy) along with additional diagnostic information.

.PARAMETER Verbose
    Displays detailed information about the agent's health including service states,
    versions, and timestamps.

.PARAMETER Json
    Returns the raw JSON response from the health endpoint.

.EXAMPLE
    .\Check-HuntressHealth.ps1
    Displays the basic health status of the Huntress agent.

.EXAMPLE
    .\Check-HuntressHealth.ps1 -Verbose
    Displays detailed health information including service states and versions.

.EXAMPLE
    .\Check-HuntressHealth.ps1 -Json
    Returns the raw JSON response from the health API.

.NOTES
    Author: Huntress Monitor
    Version: 1.0
    The Huntress agent must be installed and running for this script to work.
    The health endpoint is available at: http://localhost:24799/health
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$Json
)

# Health endpoint URL
$healthEndpoint = "http://localhost:24799/health"

try {
    Write-Verbose "Querying Huntress health endpoint at $healthEndpoint"
    
    # Query the health endpoint
    $response = Invoke-RestMethod -Uri $healthEndpoint -Method Get -ErrorAction Stop
    
    if ($Json) {
        # Return raw JSON response
        $response | ConvertTo-Json -Depth 10
        return
    }
    
    # Display health status with color coding
    Write-Host "`nHuntress Agent Health Check" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan
    
    $status = $response.status
    $statusColor = switch ($status) {
        "Healthy" { "Green" }
        "Degraded" { "Yellow" }
        "Unhealthy" { "Red" }
        default { "White" }
    }
    
    Write-Host "`nOverall Status: " -NoNewline
    Write-Host $status -ForegroundColor $statusColor
    
    if ($response.message) {
        Write-Host "Message: $($response.message)"
    }
    
    # Display detailed information in verbose mode
    if ($VerbosePreference -eq 'Continue' -or $PSBoundParameters.ContainsKey('Verbose')) {
        if ($response.serviceStates) {
            Write-Host "`nService States:" -ForegroundColor Cyan
            $response.serviceStates.PSObject.Properties | ForEach-Object {
                $serviceStatus = if ($_.Value -eq "Running") { "Green" } else { "Red" }
                Write-Host "  $($_.Name): " -NoNewline
                Write-Host $_.Value -ForegroundColor $serviceStatus
            }
        }
        
        if ($response.versions) {
            Write-Host "`nVersions:" -ForegroundColor Cyan
            $response.versions.PSObject.Properties | ForEach-Object {
                Write-Host "  $($_.Name): $($_.Value)"
            }
        }
        
        if ($response.timestamps) {
            Write-Host "`nTimestamps:" -ForegroundColor Cyan
            $response.timestamps.PSObject.Properties | ForEach-Object {
                Write-Host "  $($_.Name): $($_.Value)"
            }
        }
        
        if ($response.connectivity) {
            Write-Host "`nConnectivity:" -ForegroundColor Cyan
            $response.connectivity.PSObject.Properties | ForEach-Object {
                Write-Host "  $($_.Name): $($_.Value)"
            }
        }
    }
    
    Write-Host "`n" -NoNewline
    
    # Set exit code based on status
    switch ($status) {
        "Healthy" { 
            exit 0 
        }
        "Degraded" { 
            exit 1 
        }
        "Unhealthy" { 
            exit 2 
        }
        default { 
            exit 3 
        }
    }
    
} catch {
    Write-Host "`nError: Unable to reach Huntress health endpoint" -ForegroundColor Red
    Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nPossible causes:" -ForegroundColor Yellow
    Write-Host "  - Huntress agent is not installed"
    Write-Host "  - Huntress agent is not running"
    Write-Host "  - Health API endpoint is not accessible"
    Write-Host "`nPlease ensure the Huntress agent is installed and running."
    exit 10
}
