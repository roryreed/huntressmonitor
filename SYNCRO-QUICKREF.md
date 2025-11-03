# Syncro Integration Quick Reference

Quick reference guide for using HuntressMonitor with Syncro RMM.

## Command Reference

### Basic Commands

| Command | Description |
|---------|-------------|
| `.\Check-HuntressHealth.ps1` | Standard health check (no Syncro) |
| `.\Check-HuntressHealth.ps1 -AlertSyncro` | Health check + send to Syncro |
| `.\Check-HuntressHealth.ps1 -AlertSyncro -Verbose` | With detailed logging |
| `.\Check-HuntressHealth.ps1 -AlertSyncro -SyncroFieldPrefix "hnt_"` | Custom field prefix |

### Parameter Reference

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-AlertSyncro` | Switch | Off | Enable Syncro integration |
| `-SyncroFieldPrefix` | String | `"huntress_"` | Prefix for custom field names |
| `-Verbose` | Switch | Off | Show detailed logging |
| `-Json` | Switch | Off | Output raw JSON (no Syncro) |

## Syncro Field Reference

### Default Fields (prefix: "huntress_")

| Field Name | Type | Example Value | Description |
|------------|------|---------------|-------------|
| `huntress_status` | String | "Healthy" | Health status: Healthy, Degraded, or Unhealthy |
| `huntress_last_check` | DateTime | "2025-11-03 00:15:30" | Timestamp of last check |
| `huntress_message` | String | "All systems operational" | Status message |
| `huntress_agent_version` | String | "1.2.3" | Huntress agent version |
| `huntress_services` | String | "HuntressAgent:Running, ..." | Service states summary |

### With Custom Prefix (e.g., "hnt_")

| Field Name | Type | Example Value |
|------------|------|---------------|
| `hnt_status` | String | "Healthy" |
| `hnt_last_check` | DateTime | "2025-11-03 00:15:30" |
| `hnt_message` | String | "All systems operational" |
| `hnt_agent_version` | String | "1.2.3" |
| `hnt_services` | String | "HuntressAgent:Running, ..." |

## Exit Codes

| Exit Code | Status | Description |
|-----------|--------|-------------|
| 0 | Success | Agent is healthy |
| 1 | Warning | Agent is degraded |
| 2 | Error | Agent is unhealthy |
| 3 | Unknown | Status could not be determined |
| 10 | Error | Cannot reach health endpoint |

## Syncro Installation Paths

The script checks these locations for Syncro client:

1. `C:\Program Files\RepairTech\Syncro\kabuto.exe`
2. `C:\Program Files (x86)\RepairTech\Syncro\kabuto.exe`
3. `C:\Program Files\RepairTech\Syncro\Syncro.Service.Runner.exe`
4. `C:\Program Files (x86)\RepairTech\Syncro\Syncro.Service.Runner.exe`
5. `C:\ProgramData\Syncro\kabuto.exe`
6. `C:\ProgramData\RepairTech\Syncro\kabuto.exe`

## Common Use Cases

### 1. Scheduled Monitoring
```powershell
# Run every 15 minutes via Task Scheduler
.\Check-HuntressHealth.ps1 -AlertSyncro
```

### 2. On-Demand Check
```powershell
# Manual check with detailed output
.\Check-HuntressHealth.ps1 -AlertSyncro -Verbose
```

### 3. Multi-Environment
```powershell
# Production
.\Check-HuntressHealth.ps1 -AlertSyncro -SyncroFieldPrefix "prod_huntress_"

# Staging
.\Check-HuntressHealth.ps1 -AlertSyncro -SyncroFieldPrefix "stage_huntress_"
```

### 4. Conditional Alerting
```powershell
# Only alert on problems
$result = .\Check-HuntressHealth.ps1 -Json | ConvertFrom-Json
if ($result.status -ne "Healthy") {
    .\Check-HuntressHealth.ps1 -AlertSyncro
}
```

## Syncro Alert Rules

### Alert on Degraded Status
```
Field: huntress_status
Condition: Equals "Degraded"
Action: Create Ticket (Low Priority)
```

### Alert on Unhealthy Status
```
Field: huntress_status
Condition: Equals "Unhealthy"
Action: Create Ticket (High Priority) + Email + SMS
```

### Alert on Stale Data
```
Field: huntress_last_check
Condition: Older than 30 minutes
Action: Create Ticket (Medium Priority)
```

## Troubleshooting Quick Fixes

### Problem: "Syncro client not found"
**Solution:**
```powershell
# Verify Syncro installation
Test-Path "C:\Program Files\RepairTech\Syncro\kabuto.exe"

# If false, install/reinstall Syncro client
```

### Problem: Fields not updating
**Solution:**
```powershell
# Run with verbose to see errors
.\Check-HuntressHealth.ps1 -AlertSyncro -Verbose

# Check Syncro service is running
Get-Service | Where-Object { $_.Name -like "*Syncro*" }
```

### Problem: Permission errors
**Solution:**
```powershell
# Run as Administrator
# Or check Syncro service account permissions
```

## Testing

### Test Detection
```powershell
# Run Syncro integration test
.\Test-SyncroIntegration.ps1 -TestScenario "Installed"
```

### Test Without Syncro
```powershell
# See what happens when Syncro is not installed
.\Test-SyncroIntegration.ps1 -TestScenario "NotInstalled"
```

### Validate Syntax
```powershell
# Check script syntax
Get-Command .\Check-HuntressHealth.ps1 | Out-Null
Write-Host "Syntax OK"
```

## Performance Notes

- **Execution Time**: < 5 seconds (typical)
- **Network Usage**: None (local communication only)
- **CPU Impact**: Minimal
- **Recommended Frequency**: Every 15-30 minutes
- **Syncro API Calls**: 5 calls per execution (one per field)

## Security Checklist

- ✅ Local communication only
- ✅ No sensitive data transmitted
- ✅ Uses official Syncro CLI
- ✅ No hardcoded credentials
- ✅ Authenticated Syncro client required
- ✅ Read-only health API access

## Support Resources

- **Main Documentation**: README.md
- **Detailed Examples**: SYNCRO-EXAMPLES.md
- **Test Script**: Test-SyncroIntegration.ps1
- **Huntress Health API**: http://localhost:24799/health
- **Syncro Logs**: C:\ProgramData\RepairTech\Syncro\Logs\

## Quick Deployment

1. Download HuntressMonitor scripts
2. Verify Syncro is installed
3. Test: `.\Check-HuntressHealth.ps1 -AlertSyncro -Verbose`
4. Create scheduled task (every 15 minutes)
5. Configure Syncro alert rules
6. Monitor Syncro dashboard

## Version History

- **v2.0**: Added Syncro integration
- **v1.0**: Initial health check functionality
