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

.SYNCRO INTEGRATION
    This script can emit Syncro-friendly alert output using optional parameters.
    When -SyncroMode is used, the script writes a concise summary line and
    preserves exit codes for policy-based alerting/ticketing in Syncro.
    Suggested variables (map to Syncro Script Variables or Custom Fields):
      -CustomerName, -SiteName, -AlertName
      -SeverityMapHealthy, -SeverityMapDegraded, -SeverityMapUnhealthy
      -CreateTicket, -EmailNotify, -TimeoutSeconds
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$Json,

    # Syncro integration (all optional)
    [Parameter(Mandatory=$false)]
    [switch]$SyncroMode,

    [Parameter(Mandatory=$false)]
    [string]$CustomerName,

    [Parameter(Mandatory=$false)]
    [string]$SiteName,

    [Parameter(Mandatory=$false)]
    [string]$AlertName = "Huntress Agent Health",

    [Parameter(Mandatory=$false)]
    [string]$SeverityMapHealthy = "info",

    [Parameter(Mandatory=$false)]
    [string]$SeverityMapDegraded = "warning",

    [Parameter(Mandatory=$false)]
    [string]$SeverityMapUnhealthy = "critical",

    [Parameter(Mandatory=$false)]
    [bool]$CreateTicket = $false,

    [Parameter(Mandatory=$false)]
    [string]$EmailNotify = "",

    [Parameter(Mandatory=$false)]
    [int]$TimeoutSeconds = 10
)

# Health endpoint URL
$healthEndpoint = "http://localhost:24799/health"

# Helper to resolve hostname cross-platform
function Get-LocalHostname {
    if ($env:COMPUTERNAME) { return $env:COMPUTERNAME }
    if ($env:HOSTNAME) { return $env:HOSTNAME }
    try { return [System.Net.Dns]::GetHostName() } catch { return "unknown-host" }
}

# Helper to map exit code to severity strings for Syncro
function Get-SeverityFromExitCode {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Code,
        [string]$Healthy = $SeverityMapHealthy,
        [string]$Degraded = $SeverityMapDegraded,
        [string]$Unhealthy = $SeverityMapUnhealthy
    )
    switch ($Code) {
        0 { return $Healthy }
        1 { return $Degraded }
        2 { return $Unhealthy }
        default { return $Unhealthy }
    }
}

try {
    Write-Verbose "Querying Huntress health endpoint at $healthEndpoint"
    
    # Query the health endpoint
    $cancellationTokenSource = New-Object System.Threading.CancellationTokenSource
    $job = Start-Job -ScriptBlock {
        param($endpoint)
        Invoke-RestMethod -Uri $endpoint -Method Get -ErrorAction Stop
    } -ArgumentList $healthEndpoint

    if (-not $job | Wait-Job -Timeout $TimeoutSeconds) {
        Stop-Job -Job $job -ErrorAction SilentlyContinue | Out-Null
        throw "Health request timed out after $TimeoutSeconds seconds."
    }
    $response = Receive-Job -Job $job -ErrorAction Stop
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue | Out-Null
    
    if ($Json) {
        # Return raw JSON response
        $response | ConvertTo-Json -Depth 10
        exit 0
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
    
    # Determine exit code based on status
    $exitCode = switch ($status) {
        "Healthy" { 0 }
        "Degraded" { 1 }
        "Unhealthy" { 2 }
        default { 3 }
    }

    # Emit Syncro-friendly summary if requested
    if ($SyncroMode) {
        $hostname = Get-LocalHostname
        $severity = Get-SeverityFromExitCode -Code $exitCode
        $cust = if ($CustomerName) { $CustomerName } else { "" }
        $site = if ($SiteName) { $SiteName } else { "" }
        $msg = if ($response.message) { $response.message } else { "" }
        $short = if ($exitCode -eq 0) { "OK" } else { "ALERT" }

        # Compact, parseable line for RMM parsing or search
        Write-Output ("{0}: {1} | Status={2} | Severity={3} | Asset={4} | Customer={5} | Site={6} | CreateTicket={7} | Detail={8}" -f `
            $short, $AlertName, $status, $severity, $hostname, $cust, $site, $CreateTicket, $msg)
    }

    exit $exitCode
    
} catch {
    Write-Host "`nError: Unable to reach Huntress health endpoint" -ForegroundColor Red
    Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nPossible causes:" -ForegroundColor Yellow
    Write-Host "  - Huntress agent is not installed"
    Write-Host "  - Huntress agent is not running"
    Write-Host "  - Health API endpoint is not accessible"
    Write-Host "`nPlease ensure the Huntress agent is installed and running."
    if ($SyncroMode) {
        $hostname = Get-LocalHostname
        $severity = $SeverityMapUnhealthy
        Write-Output ("ALERT: {0} | Status=Error | Severity={1} | Asset={2} | Customer={3} | Site={4} | CreateTicket={5} | Detail={6}" -f `
            $AlertName, $severity, $hostname, $CustomerName, $SiteName, $CreateTicket, $_.Exception.Message)
    }
    exit 10
}
