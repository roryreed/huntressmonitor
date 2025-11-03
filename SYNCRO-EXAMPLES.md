# Syncro Integration Examples

This document provides practical examples and use cases for integrating HuntressMonitor with Syncro RMM.

## Quick Start

### Basic Syncro Alert
```powershell
.\Check-HuntressHealth.ps1 -AlertSyncro
```

This command:
1. Checks Huntress agent health
2. Detects Syncro client installation
3. Sends health data to Syncro custom asset fields
4. Uses default field prefix "huntress_"

### With Custom Field Prefix
```powershell
.\Check-HuntressHealth.ps1 -AlertSyncro -SyncroFieldPrefix "hnt_"
```

Creates fields like: `hnt_status`, `hnt_last_check`, `hnt_agent_version`

### With Verbose Output
```powershell
.\Check-HuntressHealth.ps1 -AlertSyncro -Verbose
```

Shows detailed logging of:
- Syncro detection process
- Field updates
- Any errors or warnings

## Scheduled Task Examples

### Example 1: Basic Scheduled Monitoring
Create a scheduled task that runs every 15 minutes:

**PowerShell Script (monitor-huntress.ps1):**
```powershell
# Navigate to script directory
Set-Location "C:\Scripts\HuntressMonitor"

# Run health check with Syncro integration
.\Check-HuntressHealth.ps1 -AlertSyncro

# Log exit code
$exitCode = $LASTEXITCODE
Add-Content -Path "C:\Logs\huntress-monitor.log" -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Exit Code: $exitCode"
```

**Task Scheduler Command:**
```cmd
powershell.exe -ExecutionPolicy Bypass -File "C:\Scripts\HuntressMonitor\monitor-huntress.ps1"
```

### Example 2: Alert on Failures Only
Only update Syncro when there are issues:

```powershell
# Check health
$result = & .\Check-HuntressHealth.ps1 -Json | ConvertFrom-Json

# Only send to Syncro if not healthy
if ($result.status -ne "Healthy") {
    .\Check-HuntressHealth.ps1 -AlertSyncro
}
```

### Example 3: Scheduled with Email Backup
Send health data to Syncro and email on critical issues:

```powershell
# Run health check with Syncro integration
& .\Check-HuntressHealth.ps1 -AlertSyncro

$exitCode = $LASTEXITCODE

# If unhealthy, also send email
if ($exitCode -eq 2) {
    $mailParams = @{
        To = "admin@company.com"
        From = "monitoring@company.com"
        Subject = "CRITICAL: Huntress Agent Unhealthy on $env:COMPUTERNAME"
        Body = "Huntress agent health check failed. Check Syncro dashboard for details."
        SmtpServer = "smtp.company.com"
    }
    Send-MailMessage @mailParams
}
```

## Syncro Alert Configuration

Once HuntressMonitor is sending data to Syncro, configure alerts in Syncro:

### Alert Rule 1: Degraded Status
- **Field**: `huntress_status`
- **Condition**: equals "Degraded"
- **Action**: Create low-priority ticket
- **Notification**: Email tech team

### Alert Rule 2: Unhealthy Status
- **Field**: `huntress_status`
- **Condition**: equals "Unhealthy"
- **Action**: Create high-priority ticket
- **Notification**: Email and SMS to on-call tech

### Alert Rule 3: Stale Health Check
- **Field**: `huntress_last_check`
- **Condition**: older than 30 minutes
- **Action**: Create ticket
- **Notification**: Email admin
- **Note**: Indicates monitoring script may have stopped running

### Alert Rule 4: Version Tracking
- **Field**: `huntress_agent_version`
- **Condition**: not equals "latest_version"
- **Action**: Create ticket for update
- **Notification**: Email tech team

## Integration Patterns

### Pattern 1: Multi-Site Monitoring
For organizations with multiple sites:

```powershell
# Add site identifier to field prefix
$site = "NYC-Office1"
.\Check-HuntressHealth.ps1 -AlertSyncro -SyncroFieldPrefix "huntress_${site}_"
```

Creates fields like: `huntress_NYC-Office1_status`

### Pattern 2: Compliance Reporting
Regular health checks for compliance:

```powershell
# Daily compliance check at 2 AM
# Save results and send to Syncro
$jsonResult = .\Check-HuntressHealth.ps1 -Json
$jsonResult | Out-File "C:\Compliance\Huntress\$(Get-Date -Format 'yyyy-MM-dd').json"

# Send to Syncro
.\Check-HuntressHealth.ps1 -AlertSyncro
```

### Pattern 3: Proactive Monitoring with Pre-checks
Check system resources before running health check:

```powershell
# Check if system is idle enough for monitoring
$cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue

if ($cpuUsage -lt 80) {
    # System not too busy, run health check
    .\Check-HuntressHealth.ps1 -AlertSyncro -Verbose
} else {
    Write-Host "System too busy, skipping health check"
}
```

### Pattern 4: Integration with Other Monitoring
Combine with other monitoring tools:

```powershell
# Check Huntress
.\Check-HuntressHealth.ps1 -AlertSyncro -SyncroFieldPrefix "security_huntress_"

# Check other security tools
.\Check-Antivirus.ps1 -AlertSyncro -SyncroFieldPrefix "security_av_"
.\Check-Firewall.ps1 -AlertSyncro -SyncroFieldPrefix "security_fw_"
```

## Troubleshooting Examples

### Debug Syncro Connection
```powershell
# Run with verbose to see detailed Syncro interaction
.\Check-HuntressHealth.ps1 -AlertSyncro -Verbose
```

### Test Syncro Installation
```powershell
# Check if Syncro client is detected
$syncroPath = Test-Path "C:\Program Files\RepairTech\Syncro\kabuto.exe"
if ($syncroPath) {
    Write-Host "Syncro client found"
} else {
    Write-Host "Syncro client NOT found"
}
```

### Manual Field Update Test
```powershell
# Manually test setting a Syncro field
$syncroExe = "C:\Program Files\RepairTech\Syncro\kabuto.exe"
& $syncroExe asset_field set "test_field" "test_value"
```

## Advanced Configuration

### Custom Field Mapping
Create a wrapper script with custom field names:

```powershell
# custom-syncro-monitoring.ps1
param(
    [string]$Environment = "Production"
)

# Set custom prefix based on environment
$prefix = "hunt_${Environment}_".ToLower()

# Run with custom prefix
.\Check-HuntressHealth.ps1 -AlertSyncro -SyncroFieldPrefix $prefix

# Example outputs:
# Production: hunt_production_status
# Staging: hunt_staging_status
```

### Retry Logic
Add retry logic for reliability:

```powershell
$maxRetries = 3
$retryCount = 0
$success = $false

while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        .\Check-HuntressHealth.ps1 -AlertSyncro -ErrorAction Stop
        $success = $true
    } catch {
        $retryCount++
        Write-Host "Attempt $retryCount failed, retrying in 30 seconds..."
        Start-Sleep -Seconds 30
    }
}
```

### Dashboard Integration
Export data for custom dashboards:

```powershell
# Get JSON data
$healthData = .\Check-HuntressHealth.ps1 -Json | ConvertFrom-Json

# Send to Syncro
.\Check-HuntressHealth.ps1 -AlertSyncro

# Also export for custom dashboard
$dashboardData = @{
    Timestamp = Get-Date
    Status = $healthData.status
    Message = $healthData.message
    AgentVersion = $healthData.versions.Agent
    Services = $healthData.serviceStates
}

$dashboardData | ConvertTo-Json | Out-File "C:\Dashboard\huntress-latest.json"
```

## Best Practices

1. **Frequency**: Run checks every 15-30 minutes for timely alerts
2. **Logging**: Always log results for troubleshooting
3. **Alerting**: Configure Syncro alerts for automated response
4. **Prefix**: Use descriptive prefixes for multi-tenant environments
5. **Testing**: Test with `-Verbose` before production deployment
6. **Monitoring**: Monitor the monitoring script itself for failures
7. **Documentation**: Document custom field meanings in Syncro
8. **Cleanup**: Periodically review and clean old field values
9. **Security**: Ensure scripts run with appropriate permissions
10. **Backup**: Have fallback alerting if Syncro is unavailable

## Support

For issues or questions:
- Check the main README.md for detailed documentation
- Run test script: `.\Test-SyncroIntegration.ps1`
- Enable verbose mode for debugging
- Review Syncro client logs at: `C:\ProgramData\RepairTech\Syncro\Logs\`
