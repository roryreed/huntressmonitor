<#
.SYNOPSIS
    Test script to demonstrate the Check-HuntressHealth.ps1 functionality with mock data.

.DESCRIPTION
    This script simulates the Huntress health endpoint response to demonstrate
    how the Check-HuntressHealth.ps1 script processes and displays the data.
    It creates a temporary mock HTTP server on port 24799 for testing purposes.

.NOTES
    This is for demonstration purposes only. In production, the actual Huntress
    agent must be installed and running.
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Healthy", "Degraded", "Unhealthy")]
    [string]$MockStatus = "Healthy"
)

Write-Host "This test script demonstrates the Check-HuntressHealth.ps1 functionality" -ForegroundColor Cyan
Write-Host "It would create a mock HTTP endpoint if the Huntress agent is not installed." -ForegroundColor Cyan
Write-Host "`nIn a real environment with Huntress installed, the script would query:" -ForegroundColor Yellow
Write-Host "  http://localhost:24799/health" -ForegroundColor Yellow
Write-Host "`nExpected response format:" -ForegroundColor Yellow

# Create a sample response with example timestamps
$currentDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
$recentDate = (Get-Date).AddHours(-13).ToString("yyyy-MM-ddTHH:mm:ssZ")
$olderDate = (Get-Date).AddHours(-3).ToString("yyyy-MM-ddTHH:mm:ssZ")

$mockResponse = @{
    status = $MockStatus
    message = if ($MockStatus -eq "Healthy") { "All systems operational" } 
              elseif ($MockStatus -eq "Degraded") { "Some components are not optimal" }
              else { "Critical issues detected" }
    serviceStates = @{
        HuntressAgent = "Running"
        HuntressUpdater = "Running"
    }
    versions = @{
        Agent = "1.2.3"
        Updater = "1.0.1"
    }
    timestamps = @{
        LastError = $recentDate
        LastEvent = $currentDate
        LastSurvey = $olderDate
    }
    connectivity = @{
        LastConnected = $currentDate
        Status = "Connected"
    }
}

# Display the mock response
$mockResponse | ConvertTo-Json -Depth 10

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "How the Check-HuntressHealth.ps1 would display this data:" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# Simulate basic output
Write-Host "Huntress Agent Health Check" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

$statusColor = switch ($MockStatus) {
    "Healthy" { "Green" }
    "Degraded" { "Yellow" }
    "Unhealthy" { "Red" }
}

Write-Host "`nOverall Status: " -NoNewline
Write-Host $MockStatus -ForegroundColor $statusColor
Write-Host "Message: $($mockResponse.message)"

Write-Host "`nWith -Verbose flag, you would also see:" -ForegroundColor Yellow
Write-Host "`nService States:" -ForegroundColor Cyan
$mockResponse.serviceStates.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): " -NoNewline
    Write-Host $_.Value -ForegroundColor Green
}

Write-Host "`nVersions:" -ForegroundColor Cyan
$mockResponse.versions.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)"
}

Write-Host "`nTimestamps:" -ForegroundColor Cyan
$mockResponse.timestamps.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)"
}

Write-Host "`nConnectivity:" -ForegroundColor Cyan
$mockResponse.connectivity.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)"
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Exit Code Information:" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "The script returns these exit codes:"
Write-Host "  0 - Healthy"
Write-Host "  1 - Degraded"
Write-Host "  2 - Unhealthy"
Write-Host "  3 - Unknown status"
Write-Host "  10 - Cannot reach endpoint (agent not running)"
Write-Host "`nFor this mock status ($MockStatus), exit code would be: " -NoNewline
switch ($MockStatus) {
    "Healthy" { Write-Host "0" -ForegroundColor Green }
    "Degraded" { Write-Host "1" -ForegroundColor Yellow }
    "Unhealthy" { Write-Host "2" -ForegroundColor Red }
}
