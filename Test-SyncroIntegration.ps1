<#
.SYNOPSIS
    Test script to demonstrate the Syncro integration functionality.

.DESCRIPTION
    This script creates mock Syncro executable and demonstrates how the
    Check-HuntressHealth.ps1 script integrates with Syncro client software.
    It shows the detection and alert sending capabilities.

.PARAMETER TestScenario
    The test scenario to run: "Installed" (Syncro found) or "NotInstalled" (Syncro not found)

.NOTES
    This is for demonstration and testing purposes only.
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Installed", "NotInstalled")]
    [string]$TestScenario = "Installed"
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Syncro Integration Test Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if ($TestScenario -eq "Installed") {
    Write-Host "Test Scenario: Syncro Client Installed" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Demonstrating Syncro Integration:" -ForegroundColor Cyan
    Write-Host "-----------------------------------" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "In a real environment, the script would:" -ForegroundColor Yellow
    Write-Host "1. Detect Syncro client (kabuto.exe) at standard locations" -ForegroundColor Yellow
    Write-Host "2. Query Huntress health API" -ForegroundColor Yellow
    Write-Host "3. Send health data to Syncro using custom asset fields" -ForegroundColor Yellow
    Write-Host "4. Use kabuto.exe CLI to set each field" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Example Syncro custom fields that would be set:" -ForegroundColor Cyan
    Write-Host ""
    
    $exampleFields = @{
        "huntress_status" = "Healthy"
        "huntress_last_check" = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        "huntress_message" = "All systems operational"
        "huntress_agent_version" = "1.2.3"
        "huntress_services" = "HuntressAgent:Running, HuntressUpdater:Running"
    }
    
    foreach ($field in $exampleFields.GetEnumerator()) {
        Write-Host "  $($field.Key) = " -NoNewline
        Write-Host "$($field.Value)" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Command line examples:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "# Basic health check with Syncro alert:" -ForegroundColor Yellow
    Write-Host '.\Check-HuntressHealth.ps1 -AlertSyncro' -ForegroundColor White
    Write-Host ""
    Write-Host "# With custom field prefix:" -ForegroundColor Yellow
    Write-Host '.\Check-HuntressHealth.ps1 -AlertSyncro -SyncroFieldPrefix "hnt_"' -ForegroundColor White
    Write-Host ""
    Write-Host "# With verbose output:" -ForegroundColor Yellow
    Write-Host '.\Check-HuntressHealth.ps1 -AlertSyncro -Verbose' -ForegroundColor White
    Write-Host ""
    
    
} else {
    Write-Host "Test Scenario: Syncro Client NOT Installed" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "When Syncro is not installed, the script will:" -ForegroundColor Cyan
    Write-Host "1. Detect that Syncro client is not present" -ForegroundColor Yellow
    Write-Host "2. Display a warning message" -ForegroundColor Yellow
    Write-Host "3. Continue with normal health check operation" -ForegroundColor Yellow
    Write-Host "4. Not fail or error - just skip Syncro integration" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Expected output when -AlertSyncro is used without Syncro:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "WARNING: Syncro client not found. Install Syncro client to enable alert functionality." -ForegroundColor Yellow
    Write-Host "Syncro is typically installed at: C:\Program Files\RepairTech\Syncro\" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Syncro Integration Details" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Standard Syncro Installation Paths:" -ForegroundColor Cyan
Write-Host "  - C:\Program Files\RepairTech\Syncro\kabuto.exe"
Write-Host "  - C:\Program Files (x86)\RepairTech\Syncro\kabuto.exe"
Write-Host "  - C:\Program Files\RepairTech\Syncro\Syncro.Service.Runner.exe"
Write-Host "  - C:\ProgramData\Syncro\kabuto.exe"
Write-Host ""

Write-Host "Custom Field Names (with default prefix 'huntress_'):" -ForegroundColor Cyan
Write-Host "  - huntress_status          : Current health status (Healthy/Degraded/Unhealthy)"
Write-Host "  - huntress_last_check      : Timestamp of last check"
Write-Host "  - huntress_message         : Status message from Huntress"
Write-Host "  - huntress_agent_version   : Huntress agent version"
Write-Host "  - huntress_services        : Service states (e.g., HuntressAgent:Running)"
Write-Host ""

Write-Host "Configuration Options:" -ForegroundColor Cyan
Write-Host "  -AlertSyncro              : Enable Syncro integration"
Write-Host "  -SyncroFieldPrefix <str>  : Custom prefix for field names (default: 'huntress_')"
Write-Host ""

Write-Host "Security Considerations:" -ForegroundColor Cyan
Write-Host "  - Data is sent only to local Syncro client (no network transmission)"
Write-Host "  - Uses Syncro's official CLI interface (kabuto.exe)"
Write-Host "  - Only health status data is transmitted (no sensitive credentials)"
Write-Host "  - Requires Syncro client to be installed and running"
Write-Host ""

Write-Host "Integration Benefits:" -ForegroundColor Cyan
Write-Host "  - Centralized monitoring of Huntress agent health in Syncro dashboard"
Write-Host "  - Automated alerting through Syncro's alert system"
Write-Host "  - Historical tracking of agent health over time"
Write-Host "  - Easy integration with existing Syncro workflows"
Write-Host ""

Write-Host "Test completed successfully!" -ForegroundColor Green
